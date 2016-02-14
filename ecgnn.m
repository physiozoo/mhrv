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

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('gqpost', DEFAULT_GQPOST, @islogical);

% Get input
p.parse(rec_name, varargin{:});
gqpost = p.Results.gqpost;

%% Find R peaks
[ qrs, tm, ~, ~, qrs_outliers ] = rqrs(rec_name, 'gqpost', gqpost, varargin{:});

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

end