function [ nni, tnn, rri, trr, rri_lp, tresh_low, thresh_high ] = ecgnn(rec_name, varargin)
%ECGNN Calculate an NN-interval time series (filtered RR intervals) from ECG signal.
% Detects QRS in a given sigal, performs outlier detection and removal and calculates the beat intervals.
% This function can perform three types of different outlier detection, based on user input. By
% default, it will perform all three.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - gqconf: Path to a config file for gqrs. E.g. for analyzing non-human data it's
%                     necessary to provide gqrs with an appropriate config file for the data.
%           - use_rqrs: true/false whether to use the rqrs algorithm to detect R-peaks (gqrs
%                       detects the onset of the QRS complex).
%           - filter_gqpost: true/false whether to use gqpost to post-process QRS detections to
%                            find potentially wrong qrs-detections.
%           - filter_poincare: true/false whether to use poincare ellipse-fitting to detect
%                              potential outliers in the rr-intervals.
%           - filter_lowpass: true/false whether to use an averaging filter to detect potential
%                             outliers in the rr-intervals. If an interval is greater (abs) than
%                             'win_percent' percent of the average in a window of size
%                             'win_samples' around it, excludes the interval.
%           - win_samples: Number of samples in the filter window on each side of the current sample
%                          (total window size will be 2*win_samples+1). Default: 10.
%           - win_percent: The percentage above/below the average to use for filtering. Default: 20.
%           - from: Number of first sample to start detecting from (default 1)
%           - to: Number of last sample to detect until (default [], i.e. end of signal)
%           - plot: true/false whether to generate a plot. Defaults to true if no output arguments
%                   were specified.
%   Outputs:
%       - nni: NN-intervals (RR intervals after removing outliers) values in seconds
%       - tnn: NN-interval times in seconds
%       - rri: RR-intervals values in seconds (Original intervals, before outlier removal)
%       - trr: RR-interval times in seconds
%       - rri_lp: Values of averaging filter (if 'filter_lowpass' was used)
%       - tresh_low: Values of lower-filtering threshold (if 'filter_lowpass' was used)
%       - tresh_high: Values of higher-filtering threshold (if 'filter_lowpass' was used)

%% Input

% Defaults
DEFAULT_GQCONF = rhrv_default('rqrs.gqconf','');
DEFAULT_USE_RQRS = true;
DEFAULT_FILTER_GQPOST = false;
DEFAULT_FILTER_POINCARE = rhrv_default('rrfilt.filter_poincare', true);
DEFAULT_FILTER_LOWPASS = rhrv_default('rrfilt.filter_lowpass', true);
DEFAULT_WIN_SAMPLES = rhrv_default('rrfilt.win_samples', 10); % samples
DEFAULT_WIN_PERCENT = rhrv_default('rrfilt.win_percent', 20); % percentage [0-100]
DEFAULT_FROM_SAMPLE = 1;
DEFAULT_TO_SAMPLE = [];
DEFAULT_ECG_CHANNEL = [];

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('gqconf', DEFAULT_GQCONF, @isstr);
p.addParameter('use_rqrs', DEFAULT_USE_RQRS, @(x) islogical(x) && isscalar(x));
p.addParameter('filter_gqpost', DEFAULT_FILTER_GQPOST, @(x) islogical(x) && isscalar(x));
p.addParameter('filter_poincare', DEFAULT_FILTER_POINCARE, @(x) islogical(x) && isscalar(x));
p.addParameter('filter_lowpass', DEFAULT_FILTER_LOWPASS, @(x) islogical(x) && isscalar(x));
p.addParameter('win_samples', DEFAULT_WIN_SAMPLES, @isnumeric);
p.addParameter('win_percent', DEFAULT_WIN_PERCENT, @(x) x >= 0 && x <= 100);
p.addParameter('from', DEFAULT_FROM_SAMPLE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('to', DEFAULT_TO_SAMPLE, @(x) isnumeric(x) && (isscalar(x)||isempty(x)));
p.addParameter('ecg_channel', DEFAULT_ECG_CHANNEL, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
filter_gqpost = p.Results.filter_gqpost;
gqconf = p.Results.gqconf;
use_rqrs = p.Results.use_rqrs;
filter_poincare = p.Results.filter_poincare;
filter_lowpass = p.Results.filter_lowpass;
win_samples = p.Results.win_samples;
win_percent = p.Results.win_percent;
from_sample = p.Results.from;
to_sample = p.Results.to;
ecg_channel = p.Results.ecg_channel;
should_plot = p.Results.plot;

% Check output
if (nargout > 4 && ~filter_lowpass)
    error('Low-pass filter outputs can''t be set without ''filter_lowpass'' option');
end

%% QRS detection

% Make sure we have an ECG channel in the record
if (isempty(ecg_channel))
    ecg_channel = get_signal_channel(rec_name);
    if (isempty(ecg_channel))
        error('Failed to find an ECG channel in the record %s', rec_name);
    end
end

% Read the signal
[tm, sig, ~] = rdsamp(rec_name, ecg_channel, 'from', from_sample, 'to', to_sample);

% Use gqrs to find QRS complex locations
[qrs, qrs_outliers] = gqrs(rec_name, 'ecg_col', ecg_channel, 'gqpost', filter_gqpost, 'gqconf', gqconf,...
                           'from', from_sample, 'to', to_sample);

% Use rqrs to find the R-peaks based on the qrs complex locations
if (use_rqrs)
    [qrs, qrs_outliers] = rqrs_augment(qrs, qrs_outliers, tm, sig);
end

% Make sure we got detections before continuing (it's possible to get none in e.g. very noisy
% parts of a signal)
if (isempty(qrs))
    nni=[]; tnn=[]; rri=[]; trr=[]; rri_lp=[]; tresh_low=[]; thresh_high=[];
    return;
end

%% RR intervals

% RR-intervals are the time-difference between R-Peaks
rri = diff(tm(qrs));
trr = tm(qrs(1:end-1));

%% GQPOST-based outlier detection

gqpost_outliers = [];
if (filter_gqpost)
    % create a time axis where outliers are marked with NaN
    tm_nan = tm;
    tm_nan(qrs_outliers) = NaN;

    % For each NaN index in the time axis, also mark the previous index as NaN
    % (since we drop two intervals per outlier)
    trr_nan = tm_nan(qrs(1:end-1));
    nanidx = find(isnan(trr_nan));

    % Set the outlier indexes in of the RR intervals: For each GQPOST outlier, we have two intervals
    % that are considered outliers (the interval before the outlier peak and the one after).
    gqpost_outliers = [nanidx; nanidx-1];
end

%% Poincare-based outlier detection

poincare_outliers = [];
if (filter_poincare)
    [~, ~, poincare_outliers] = poincare(rri, 'plot', should_plot);
end

%% Lowpass-filter-based outlier detection

lp_outliers = [];
if (filter_lowpass)
    % Filter the NN intervals with a moving average window
    b_fir = 1/(2 * win_samples) .* [ones(win_samples,1); 0; ones(win_samples,1)];
    rri_lp = filtfilt(b_fir, 1, rri); % using filtfilt for zero-phase

    % Find outliers
    lp_outliers = find( abs(rri - rri_lp) > (win_percent/100) .* rri_lp );

    % Save threshold lines if necessary
    if (nargout > 4 || should_plot)
        tresh_low   = rri_lp.*(1.0-win_percent/100);
        thresh_high = rri_lp.*(1.0+win_percent/100);
    end
end

%% Calculate filtered intervals

all_outliers = unique([gqpost_outliers(:); poincare_outliers(:); lp_outliers(:)]);
tnn = trr;
nni = rri;

tnn(all_outliers) = [];
nni(all_outliers) = [];

%% Plot if no output args or if requested
if (should_plot)
    markersize = 8.0;

    figure; hold on; grid on;
    plot(tm, sig);
    plot(tm(qrs), sig(qrs,1), 'rx', 'MarkerSize', markersize);
    xlabel('time [s]'); ylabel('ECG [mV]');
    legend('ECG signal', sprintf('%s-peaks', char(use_rqrs * 'R' + (~use_rqrs)*'Q')));

    figure; hold on; grid on;
    xlabel('time [s]'); ylabel('RR Intervals [s]');

    % Plot original intervals
    plot(trr, rri ,'b-', 'LineWidth', 2);
    legend_labels = {'RR intervals'};

    % Plot filtered intervals
    plot(tnn, nni, 'g-', 'LineWidth', 1);
    legend_labels{end+1} = 'Filtered intervals';

    if (~isempty(gqpost_outliers))
        plot(trr(gqpost_outliers), rri(gqpost_outliers), 'm^', 'MarkerSize', markersize+1);
        legend_labels{end+1} = 'gqpost outliers';
    end

    if (~isempty(poincare_outliers))
        plot(trr(poincare_outliers), rri(poincare_outliers), 'rx', 'MarkerSize', markersize);
        legend_labels{end+1} = 'Poincare outliers';
    end

    if (~isempty(lp_outliers))
        plot(trr(lp_outliers), rri(lp_outliers), 'ko', 'MarkerSize', markersize);
        legend_labels{end+1} = 'Lowpass outliers';
    end

    % Plot window average and thresholds
    if (filter_lowpass)
        plot(trr, rri_lp, 'k', trr, tresh_low, 'k--', trr, thresh_high, 'k--');
        legend_labels = [legend_labels, {'window average', 'window threshold'}];
    end

    legend(legend_labels);
end

end