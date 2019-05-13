function [ nni, tnn, plot_data ] = filtrr( rri, trr, varargin )
%Calculate an NN-interval time series (filtered RR intervals).  Performs
%outlier detection and removal on RR interval data.  This function can perform
%three types of different outlier detection, based on user input: Range based
%detection, moving-average filter-based detection and quotient filter based
%detection.
%
%:param rri: RR-intervals values in seconds.
%:param trr: RR-interval times in seconds.
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - filter_range: true/false whether to use range filtering (remove intervals
%     smaller or larger than 'rr_min' and 'rr_max').
%   - filter_ma: true/false whether to use a moving-average filter to detect
%     potential outliers in the rr-intervals. If an interval is greater (abs)
%     than 'win_percent' percent of the average in a window of size 'win_samples'
%     around it, excludes the interval.
%   - filter_quotient: true/false whether to use the quotient filter. This
%     fliter checks the quotient between an interval and it's predecessor and
%     successors, and only allows a configured change percentage
%     ('rr_max_change') between them.
%   - win_samples: Number of samples in the filter window on each side of the
%     current sample (total window size will be 2*win_samples+1). Default: 10.
%   - win_percent: The percentage above/below the average to use for filtering.
%     Default: 20.
%   - rr_min: Min physiological RR interval, in seconds. Intervals shorter than
%     this will be removed prior to poincare plotting. Default: 0.32 sec.
%   - rr_max: Max physiological RR interval, in seconds. Intervals longer
%     than this will be removed prior to poincare plotting. Default: 1.5 sec.
%   - rr_max_change: Maximal change, in percent, allowed between adjacent RR
%     intervals.  Intervals violating this will be removed prior to poincare
%     plotting. Default: 25.
%   - plot: true/false whether to generate a plot. Defaults to true if no
%     output arguments were specified.
%
%:returns:
%
%   - nni: NN-intervals (RR intervals after removing outliers) values in seconds
%   - tnn: NN-interval times in seconds
%

import mhrv.defaults.*;

%% Input

% Defaults
DEFAULT_FILTER_RANGE = mhrv_get_default('filtrr.range.enable', 'value');
DEFAULT_FILTER_MA = mhrv_get_default('filtrr.moving_average.enable', 'value');
DEFAULT_FILTER_QUOTIENT = mhrv_get_default('filtrr.quotient.enable', 'value');

DEFAULT_RR_MIN = mhrv_get_default('filtrr.range.rr_min', 'value');
DEFAULT_RR_MAX = mhrv_get_default('filtrr.range.rr_max', 'value');

DEFAULT_WIN_SAMPLES = mhrv_get_default('filtrr.moving_average.win_length', 'value');
DEFAULT_WIN_PERCENT = mhrv_get_default('filtrr.moving_average.win_threshold', 'value');

DEFAULT_RR_MAX_CHANGE = mhrv_get_default('filtrr.quotient.rr_max_change', 'value');

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('trr', @(x) isnumeric(x) && ~isscalar(x) && length(x)==length(rri));

p.addParameter('filter_range', DEFAULT_FILTER_RANGE, @(x) islogical(x) && isscalar(x));
p.addParameter('rr_min', DEFAULT_RR_MIN, @(x) isnumeric(x) && isscalar(x));
p.addParameter('rr_max', DEFAULT_RR_MAX, @(x) isnumeric(x) && isscalar(x));

p.addParameter('filter_ma', DEFAULT_FILTER_MA, @(x) islogical(x) && isscalar(x));
p.addParameter('win_samples', DEFAULT_WIN_SAMPLES, @isnumeric);
p.addParameter('win_percent', DEFAULT_WIN_PERCENT, @(x) x >= 0 && x <= 100);

p.addParameter('filter_quotient', DEFAULT_FILTER_QUOTIENT, @(x) islogical(x) && isscalar(x));
p.addParameter('rr_max_change', DEFAULT_RR_MAX_CHANGE, @(x) isnumeric(x) && isscalar(x) && x>0 && x<=100);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rri, trr, varargin{:});

filter_range = p.Results.filter_range;
rr_min = p.Results.rr_min;
rr_max = p.Results.rr_max;

filter_ma = p.Results.filter_ma;
win_samples = p.Results.win_samples;
win_percent = p.Results.win_percent;

filter_quotient = p.Results.filter_quotient;
rr_max_change = p.Results.rr_max_change;

should_plot = p.Results.plot;

rri_filtered = rri;
trr_filtered = trr;

%% Range-based filtering

range_outliers_idx = [];
if filter_range
    range_outliers_idx = find(rri < rr_min | rri > rr_max);
end

rri_filtered(range_outliers_idx) = [];
range_outliers = trr_filtered(range_outliers_idx);
trr_filtered(range_outliers_idx) = [];

%% Moving average filtering

ma_outliers_idx = []; rri_ma = []; trr_ma = [];
if filter_ma
    % Filter the NN intervals with a moving average window
    b_fir = 1/(2 * win_samples) .* [ones(win_samples,1); 0; ones(win_samples,1)];
    
    rri_ma = filtfilt(b_fir, 1, rri_filtered); % using filtfilt for zero-phase
    trr_ma = trr_filtered;

    % Find outliers
    ma_outliers_idx = find( abs(rri_filtered - rri_ma) > (win_percent/100) .* rri_ma );
end

rri_filtered(ma_outliers_idx) = [];
ma_outliers = trr_filtered(ma_outliers_idx);
trr_filtered(ma_outliers_idx) = [];

%% Quotient filter

rr_max_change = rr_max_change / 100;
quotient_outliers_idx = [];
if filter_quotient
    rr_n0 = rri_filtered(1:end-1);   % RR(n)
    rr_n1 = rri_filtered(2:end);     % RR(n+1)

    rr_q_min = 1.0 - rr_max_change;
    rr_q_max = 1.0 + rr_max_change;

    % Find intervals that differ by more than a specified percentage from the prev/next interval
    quotient_outliers_idx = find(...
        rr_n0./rr_n1 < rr_q_min | rr_n0./rr_n1 > rr_q_max | ...
        rr_n1./rr_n0 < rr_q_min | rr_n1./rr_n0 > rr_q_max ...
        );
end

rri_filtered(quotient_outliers_idx) = [];
quotient_outliers = trr_filtered(quotient_outliers_idx);
trr_filtered(quotient_outliers_idx) = [];

%% Calculate filtered intervals
tnn = trr_filtered;
nni = rri_filtered;

%% Plot if no output args or if requested
plot_data.name = 'Filtered RR Intervals';
plot_data.trr = trr;
plot_data.rri = rri;
plot_data.tnn = tnn;
plot_data.nni = nni;
plot_data.range_outliers = range_outliers;
plot_data.ma_outliers = ma_outliers;
plot_data.quotient_outliers = quotient_outliers;
plot_data.trr_ma = trr_ma;
plot_data.rri_ma = rri_ma;
plot_data.win_percent = win_percent;

if (should_plot)
    figure('Name', plot_data.name);
    plot_filtrr(gca, plot_data);
end

end

