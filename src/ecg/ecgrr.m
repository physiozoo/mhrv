function [ rri, trr, plot_data ] = ecgrr( rec_name, varargin )
%ECGRR Calculate an RR-interval time series from PhysioNet ECG data.
% Detects QRS in a given sigal and calculates the RR intervals.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - ann_ext: Specify an annotation file extention to use instead of loading the record
%            itself (.dat file). If provided, RR intervals will be loaded from the annotation file
%            instead of from the ECG. Default: empty (don't use annotation).
%           - ecg_channel: Number of ecg signal in the record (default [], i.e. auto-detect signal).
%           - from: Number of first sample to start detecting from (default 1)
%           - to: Number of last sample to detect until (default [], i.e. end of signal)
%           - plot: true/false whether to generate a plot. Defaults to true if no output arguments
%                   were specified.
%   Outputs:
%       - rri: RR-intervals values in seconds.
%       - trr: RR-interval times in seconds.
%

%% Input
% Defaults
DEFAULT_ANN_EXT = '';
DEFAULT_FROM_SAMPLE = 1;
DEFAULT_TO_SAMPLE = [];
DEFAULT_ECG_CHANNEL = [];

% Define input
p = inputParser;
p.addRequired('rec_name');
p.addParameter('ann_ext', DEFAULT_ANN_EXT, @(x) ischar(x));
p.addParameter('from', DEFAULT_FROM_SAMPLE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('to', DEFAULT_TO_SAMPLE, @(x) isnumeric(x) && (isscalar(x)||isempty(x)));
p.addParameter('ecg_channel', DEFAULT_ECG_CHANNEL, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
ann_ext = p.Results.ann_ext;
from_sample = p.Results.from;
to_sample = p.Results.to;
ecg_channel = p.Results.ecg_channel;
should_plot = p.Results.plot;

% Validate record
if isempty(ann_ext)
    if ~isrecord(rec_name)
        error('Can''t find data file for record %s', ann_ext, rec_name);
    end
else
    if ~isrecord(rec_name, ann_ext)
        error('Can''t find annotation %s for record %s', ann_ext, rec_name);
    end
end

%% QRS detection
% Make sure we have an ECG channel in the record
[default_ecg_channel, Fs, N] = get_signal_channel(rec_name);
if isempty(ecg_channel)
    if isempty(default_ecg_channel)
        error('No ECG channel found in record %s', rec_name);
    else
        ecg_channel = default_ecg_channel;
    end
end

% If we have an annotation extension, load annotations instead of ECG data.
if ~isempty(ann_ext)
    % Load annotations: indexes of normal beats
    ann = rdann( rec_name, ann_ext, 'from', from_sample, 'to', to_sample, 'ann_types', '"N"');

    % Calcualte the RR intervals and their absolute time in the signal based on the
    % beat indices and the sampling frequency of the record.
    start_time = (ann(1) - 1) * (1/Fs);
    rri = diff(ann) .* (1/Fs);
    trr = [0; cumsum(rri(1:end-1))] + start_time;

    % Create an empty plot data. We don't have the signal to plot in this case.
    plot_data = struct;
    return;
else
    % Use rqrs to find QRS complex locations
    [qrs, qrs_outliers, tm, sig, Fs] = rqrs(rec_name, 'ecg_channel', ecg_channel, ...
        'from', from_sample, 'to', to_sample);

    % Make sure we got detections before continuing (it's possible to get none in e.g. very noisy
    % parts of a signal)
    if (isempty(qrs))
        nni=[]; tnn=[]; rri=[]; trr=[]; rri_lp=[]; tresh_low=[]; thresh_high=[];
        return;
    end

    % RR-intervals are the time-difference between R-Peaks
    rri = diff(tm(qrs));
    trr = tm(qrs(1:end-1));

    % QRS Outlier removal
    % create a time axis where qrs outliers are marked with NaN
    tm_nan = tm;
    tm_nan(qrs_outliers) = NaN;

    % Find indices of RR intervals that start at the outlier qrs detections
    trr_nan = tm_nan(qrs(1:end-1));
    nanidx = find(isnan(trr_nan));

    % Set the outlier indexes in of the RR intervals: For each outlier, we have two intervals
    % that are considered outliers (the interval before the outlier peak and the one after).
    rr_outliers = [nanidx; nanidx-1];

    % Remove these RR intervals
    trr(rr_outliers) = [];
    rri(rr_outliers) = [];
end

%% Plot if no output args or if requested
plot_data.name = 'ECG R-peaks';
plot_data.tm = tm;
plot_data.sig = sig;
plot_data.qrs = qrs;
plot_data.qrs_outliers = qrs_outliers;

if (should_plot)
    figure('Name', plot_data.name);
    plot_ecgrr(gca, plot_data);
end
end

