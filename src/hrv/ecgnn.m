function [ nni, tnn, rri, trr ] = ecgnn(rec_name, varargin)
%ECGNN Calculate an NN-interval time series from ECG signal.
% Detects QRS in a given sigal, performs outlier detection and removal and calculates the beat intervals.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - 'gqpost': true/false whether to use gqpost to post-process QRS detections and find
%                       potentially wrong detections (suspected outliers).
%           - 'gqconf': Path to a config file for gqrs. E.g. for analyzing non-human data it's
%                       necessary to provide gqrs with an appropriate config file for the data.
%           - 'use_rqrs': true/false whether to use the rqrs algorithm to detect R-peaks (gqrs
%                         detects the onset of the QRS complex).
%           - 'plot': true/false whether to generate a plot. Defaults to true if no output
%                     arguments were specified.
%   Outputs:
%       - nni: NN-intervals values in seconds
%       - tnn: NN-interval times in seconds
%       - rri: RR-intervals values in seconds (Original intervals, before outlier removal)
%       - trr: RR-interval times in seconds

%% === Input

% Defaults
DEFAULT_GQPOST = true;
DEFAULT_GQCONF = '';
DEFAULT_USE_RQRS = true;
DEFAULT_USE_POINCARE = false;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('gqpost', DEFAULT_GQPOST, @(x) islogical(x) && isscalar(x));
p.addParameter('gqconf', DEFAULT_GQCONF, @isstr);
p.addParameter('use_rqrs', DEFAULT_USE_RQRS, @(x) islogical(x) && isscalar(x));
p.addParameter('use_poincare', DEFAULT_USE_POINCARE, @(x) islogical(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
gqpost = p.Results.gqpost;
gqconf = p.Results.gqconf;
use_rqrs = p.Results.use_rqrs;
use_poincare = p.Results.use_poincare;
should_plot = p.Results.plot;

% === Read the signal
ecg_col = get_signal_channel(rec_name);
[tm, sig, ~] = rdsamp(rec_name, ecg_col);

%% === Find QRS in the signal

% Use gqrs to find QRS complex locations
[qrs, qrs_outliers] = gqrs(rec_name, 'ecg_col', ecg_col, 'gqpost', gqpost, 'gqconf', gqconf);

% Use rqrs to find the r-peaks based on the qrs complex locations
if (use_rqrs)
    [qrs, qrs_outliers] = rqrs_augment(qrs, qrs_outliers, tm, sig);
end

%% Find RR intervals

% RR-intervals are the time-difference between R-Peaks
rri = diff(tm(qrs));
trr = tm(qrs(1:end-1));

%% Find NN intervals
% In case a qrs detection is a suspected outlier we assume it's not a normal (N) beat,
% so we don't want to take the interval before or after it.

% create a time axis where outliers are marked with NaN
tm_nan = tm;
tm_nan(qrs_outliers) = NaN;

% Calculate time difference of qrs detections. The outliers were marked
% with NaN so diff will cause two intervals to be also marked with NaN (which is what we
% want since for every outlier we need to drop two intervals).
nni = diff(tm_nan(qrs));

% Discard NaN intervals
nni(isnan(nni)) = [];

% For each NaN index in the time axis, also mark the previous index as NaN
% (since we drop two intervals per outlier)
tnn = tm_nan(qrs(1:end-1));
nanidx = find(isnan(tnn));
nanidx = [nanidx; nanidx-1];

% Take RR interval times and remove the marked indexes
tnn(nanidx) = [];

%% Poincare-based outlier detection

if (use_poincare)
    [~, ~, poincare_outliers] = poincare(nni);
    nni(poincare_outliers) = [];
    tnn(poincare_outliers) = [];
end

%% Plot if no output args or if requested
if (should_plot)
    figure; %hold on; grid on;
    p1 = subplot(2,1,1);
    plot(tm, sig); hold on; grid on;
    set( get(p1,'XLabel'), 'String', 'time [s]' );
    set( get(p1,'YLabel'), 'String', 'ECG [mV]' );

    ihr = 60 ./ nni;
    ihr_avg = mean(ihr);
    p2 = subplot(2,1,2);
    plot(tnn, ihr, tnn, ones(size(ihr)) .* ihr_avg); hold on; grid on;
    set( get(p2,'XLabel'), 'String', 'time [s]' );
    set( get(p2,'YLabel'), 'String', 'IHR [BPM]' );
    legend('IHR', sprintf('Avg.=%f', ihr_avg));
end

end