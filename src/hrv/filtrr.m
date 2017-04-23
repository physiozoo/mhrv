function [ nni, tnn, plot_data ] = filtrr( rri, trr, varargin )
%FILTRR Calculate an NN-interval time series (filtered RR intervals).
% Performs outlier detection and removal on RR interval data.
% This function can perform two types of different outlier detection, based on user input: Poincare
% based detection, and lowpass filter-based detection.
%   Inputs:
%       - rri: RR-intervals values in seconds.
%       - trr: RR-interval times in seconds.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - filter_poincare: true/false whether to use poincare plot-based filters to detect
%                              potential outliers in the rr-intervals.
%           - filter_lowpass: true/false whether to use an averaging filter to detect potential
%                             outliers in the rr-intervals. If an interval is greater (abs) than
%                             'win_percent' percent of the average in a window of size
%                             'win_samples' around it, excludes the interval.
%           - win_samples: Number of samples in the filter window on each side of the current sample
%                          (total window size will be 2*win_samples+1). Default: 10.
%           - win_percent: The percentage above/below the average to use for filtering. Default: 20.
%           - plot: true/false whether to generate a plot. Defaults to true if no output arguments
%                   were specified.
%   Outputs:
%       - nni: NN-intervals (RR intervals after removing outliers) values in seconds
%       - tnn: NN-interval times in seconds
%

%% Input

% Defaults
DEFAULT_FILTER_POINCARE = rhrv_default('filtrr.filter_poincare', true);
DEFAULT_FILTER_LOWPASS = rhrv_default('filtrr.filter_lowpass', true);
DEFAULT_WIN_SAMPLES = rhrv_default('filtrr.win_samples', 10); % samples
DEFAULT_WIN_PERCENT = rhrv_default('filtrr.win_percent', 20); % percentage [0-100]

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('trr', @(x) isnumeric(x) && ~isscalar(x) && length(x)==length(rri));
p.addParameter('filter_poincare', DEFAULT_FILTER_POINCARE, @(x) islogical(x) && isscalar(x));
p.addParameter('filter_lowpass', DEFAULT_FILTER_LOWPASS, @(x) islogical(x) && isscalar(x));
p.addParameter('win_samples', DEFAULT_WIN_SAMPLES, @isnumeric);
p.addParameter('win_percent', DEFAULT_WIN_PERCENT, @(x) x >= 0 && x <= 100);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rri, trr, varargin{:});
filter_poincare = p.Results.filter_poincare;
filter_lowpass = p.Results.filter_lowpass;
win_samples = p.Results.win_samples;
win_percent = p.Results.win_percent;
should_plot = p.Results.plot;

%% Poincare-based outlier detection

poincare_outliers = [];
if (filter_poincare)
    [~, ~, poincare_outliers, plot_data] = poincare(rri);
end

%% Lowpass-filter-based outlier detection

lp_outliers = []; rri_lp = [];
if (filter_lowpass)
    % Filter the NN intervals with a moving average window
    b_fir = 1/(2 * win_samples) .* [ones(win_samples,1); 0; ones(win_samples,1)];
    rri_lp = filtfilt(b_fir, 1, rri); % using filtfilt for zero-phase

    % Find outliers
    lp_outliers = find( abs(rri - rri_lp) > (win_percent/100) .* rri_lp );
end

%% Calculate filtered intervals

all_outliers = unique([poincare_outliers(:); lp_outliers(:)]);
tnn = trr;
nni = rri;

tnn(all_outliers) = [];
nni(all_outliers) = [];

%% Plot if no output args or if requested
plot_data.trr = trr;
plot_data.rri = rri;
plot_data.tnn = tnn;
plot_data.nni = nni;
plot_data.poincare_outliers = poincare_outliers;
plot_data.lp_outliers = lp_outliers;
plot_data.rri_lp = rri_lp;
plot_data.win_percent = win_percent;

if (should_plot)
    figure('Name', 'RR Interval Filtering');
    plot_filtrr(gca, plot_data);
end

end

