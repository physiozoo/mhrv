function [ nni, tnn, plot_data ] = filtrr( rri, trr, varargin )
%FILTRR Calculate an NN-interval time series (filtered RR intervals).
% Performs outlier detection and removal on RR interval data.
% This function can perform three types of different outlier detection, based on user input: Range
% based detection, lowpass filter-based detection and quotient filter based detection.
%   Inputs:
%       - rri: RR-intervals values in seconds.
%       - trr: RR-interval times in seconds.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - filter_range: true/false whether to use range filtering (remove intervals smaller or
%             larger than 'rr_min' and 'rr_max').
%           - filter_lowpass: true/false whether to use an averaging filter to detect potential
%             outliers in the rr-intervals. If an interval is greater (abs) than
%             'win_percent' percent of the average in a window of size 'win_samples' around it,
%              excludes the interval.
%           - filter_quotient: true/false whether to use the quotient filter. This fliter checks the
%             quotient between an interval and it's predecessor and successors, and only allows a
%             configured change percentage ('rr_max_change') between them.
%           - win_samples: Number of samples in the filter window on each side of the current sample
%                          (total window size will be 2*win_samples+1). Default: 10.
%           - win_percent: The percentage above/below the average to use for filtering. Default: 20.
%           - rr_min: Min physiological RR interval, in seconds. Intervals shorter than this will
%             be removed prior to poincare plotting. Default: 0.32 sec.
%           - rr_max: Max physiological RR interval, in seconds. Intervals longer than this will
%             be removed prior to poincare plotting. Default: 1.5 sec.
%           - rr_max_change: Maximal change, in percent, allowed between adjacent RR intervals.
%             Intervals violating this will be removed prior to poincare plotting. Default: 25.
%           - plot: true/false whether to generate a plot. Defaults to true if no output arguments
%                   were specified.
%   Outputs:
%       - nni: NN-intervals (RR intervals after removing outliers) values in seconds
%       - tnn: NN-interval times in seconds
%

%% Input

% Defaults
DEFAULT_FILTER_RANGE = rhrv_get_default('filtrr.range.enable', 'value');
DEFAULT_FILTER_LOWPASS = rhrv_get_default('filtrr.lowpass.enable', 'value');
DEFAULT_FILTER_QUOTIENT = rhrv_get_default('filtrr.quotient.enable', 'value');

DEFAULT_RR_MIN = rhrv_get_default('filtrr.range.rr_min', 'value');
DEFAULT_RR_MAX = rhrv_get_default('filtrr.range.rr_max', 'value');

DEFAULT_WIN_SAMPLES = rhrv_get_default('filtrr.lowpass.win_length', 'value');
DEFAULT_WIN_PERCENT = rhrv_get_default('filtrr.lowpass.win_threshold', 'value');

DEFAULT_RR_MAX_CHANGE = rhrv_get_default('filtrr.quotient.rr_max_change', 'value');

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('trr', @(x) isnumeric(x) && ~isscalar(x) && length(x)==length(rri));

p.addParameter('filter_range', DEFAULT_FILTER_RANGE, @(x) islogical(x) && isscalar(x));
p.addParameter('rr_min', DEFAULT_RR_MIN, @(x) isnumeric(x) && isscalar(x));
p.addParameter('rr_max', DEFAULT_RR_MAX, @(x) isnumeric(x) && isscalar(x));

p.addParameter('filter_lowpass', DEFAULT_FILTER_LOWPASS, @(x) islogical(x) && isscalar(x));
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

filter_lowpass = p.Results.filter_lowpass;
win_samples = p.Results.win_samples;
win_percent = p.Results.win_percent;

filter_quotient = p.Results.filter_quotient;
rr_max_change = p.Results.rr_max_change;

should_plot = p.Results.plot;

%% Range-based filtering

range_outliers = [];
if filter_range
    range_outliers = find(rri < rr_min | rri > rr_max);
end

%% Lowpass-filter-based filtering

lp_outliers = []; rri_lp = [];
if filter_lowpass
    % Filter the NN intervals with a moving average window
    b_fir = 1/(2 * win_samples) .* [ones(win_samples,1); 0; ones(win_samples,1)];
    rri_lp = filtfilt(b_fir, 1, rri); % using filtfilt for zero-phase

    % Find outliers
    lp_outliers = find( abs(rri - rri_lp) > (win_percent/100) .* rri_lp );
end

%% Quotient filter

rr_max_change = rr_max_change / 100;
quotient_outliers = [];
if filter_quotient
    rr_n0 = rri(1:end-1);   % RR(n)
    rr_n1 = rri(2:end);     % RR(n+1)

    rr_q_min = 1.0 - rr_max_change;
    rr_q_max = 1.0 + rr_max_change;

    % Find intervals that differ by more than a specified percentage from the prev/next interval
    quotient_outliers = find(...
        rr_n0./rr_n1 < rr_q_min | rr_n0./rr_n1 > rr_q_max | ...
        rr_n1./rr_n0 < rr_q_min | rr_n1./rr_n0 > rr_q_max ...
        );
end

%% Calculate filtered intervals
tnn = trr;
nni = rri;

all_outliers = [range_outliers(:); lp_outliers(:); quotient_outliers(:)];
tnn(all_outliers) = [];
nni(all_outliers) = [];

%% Plot if no output args or if requested
plot_data.name = 'Filtered RR Intervals';
plot_data.trr = trr;
plot_data.rri = rri;
plot_data.tnn = tnn;
plot_data.nni = nni;
plot_data.range_outliers = range_outliers;
plot_data.lp_outliers = lp_outliers;
plot_data.quotient_outliers = quotient_outliers;
plot_data.rri_lp = rri_lp;
plot_data.win_percent = win_percent;

if (should_plot)
    figure('Name', plot_data.name);
    plot_filtrr(gca, plot_data);
end

end

