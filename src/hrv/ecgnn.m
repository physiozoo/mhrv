function [ nni, tnn, rri, trr ] = ecgnn(rec_name, varargin)
%ECGNN Calculate an NN-interval time series from ECG signal.
%   rec_name - ECG signal record (physionet format)
%   nni      - NN-intervals
%   tnn      - NN-interval times
%   rri      - RR-intervals
%   trr      - RR-interval times

%% === Input

% Defaults
DEFAULT_GQPOST = true;
DEFAULT_USE_RQRS = true;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('gqpost', DEFAULT_GQPOST, @(x) islogical(x) && isscalar(x));
p.addParameter('gqconf', '', @isstr);
p.addParameter('use_rqrs', DEFAULT_USE_RQRS, @(x) islogical(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
gqpost = p.Results.gqpost;
gqconf = p.Results.gqconf;
use_rqrs = p.Results.use_rqrs;
should_plot = p.Results.plot;

% === Read the signal
ecg_col = get_signal_channel(rec_name);
[tm, sig, ~] = rdsamp(rec_name, ecg_col);

%% === Find QRS in the signal

% Use gqrs to find QRS complex locations
[qrs, qrs_outliers] = gqrs(rec_name, 'ecg_col', ecg_col, 'gqpost', gqpost, 'config', gqconf);

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