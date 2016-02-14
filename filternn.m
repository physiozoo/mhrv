function [ tnn_filtered, nni_filtered ] = filternn( tnn, nni, varargin )
%FILTERNN Filters NN intervals to remove possible outliers
%   Performs three types of filtering of NN intervals
%   1)  Removes intervals that are non-physiological (single interval is too
%       short or too long).
%   2)  Averaging filter: If an interval is greater (abs) than X percent of
%       the average in a window around it, excludes the interval. The window
%       average is calculated without the sampe itself.
%
%   These filters and their defult values are based on:
%   1) PhysioNet HRV toolkit: https://physionet.org/tutorials/hrv-toolkit/
%   2) Moody, G. B. (1993). Spectral analysis of heart rate without resampling.
%      Computers in Cardiology 1993, Proceedings., (1), 7?10.
%      Retrieved from http://ieeexplore.ieee.org/xpls/abs_all.jsp?arnumber=378302

%% === Input

% Defaults
DEFAULT_MIN_NN = 0.3; % seconds
DEFAULT_MAX_NN = 2.0; % seconds
DEFAULT_WIN_SAMPLES = 20; % samples
DEFAULT_WIN_PERCENT = 20; % percentage [0-100]

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('tnn', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('nni', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('min_nn', DEFAULT_MIN_NN, @isnumeric);
p.addParameter('max_nn', DEFAULT_MAX_NN, @isnumeric);
p.addParameter('win_samples', DEFAULT_WIN_SAMPLES, @isnumeric);
p.addParameter('win_percent', DEFAULT_WIN_PERCENT, @(x) x >= 0 && x <= 100);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(tnn, nni, varargin{:});
min_nn = p.Results.min_nn;
max_nn = p.Results.max_nn;
win_samples = p.Results.win_samples;
win_percent = p.Results.win_percent;
should_plot = p.Results.plot;

% Make sure input vectors are same length
if (length(tnn) ~= length(nni))
    error('Input vector lengths don''t match');
end

%% Initilize filtered data
nni_filtered = nni;
tnn_filtered = tnn;

%% Filter single intervals

outlier_idx1 = find( nni < min_nn | nni > max_nn );

%% Filter interval in window

% Filter the NN intervals with a moving average window
b_fir = 1/(2 * win_samples) .* [ones(win_samples,1); 0; ones(win_samples,1)];
nni_lp = filtfilt(b_fir, 1, nni); % using filtfilt for zero-phase

% Find and remove outliers
outlier_idx2 = find( abs(nni - nni_lp) > (win_percent/100) .* nni_lp );

%% Results

all_outliers_idx = [outlier_idx1; outlier_idx2];
nni_filtered(all_outliers_idx) = [];
tnn_filtered(all_outliers_idx) = [];

%% Plot if no output args
if (should_plot)
    figure; hold on; grid on;
    xlabel('time [s]'); ylabel('Intervals [s]');

    % Plot original vs. filtered
    plot(tnn, nni); % original intervals
    plot(tnn_filtered, nni_filtered, 'g:'); % filtered intervals
    legend_labels = {'original', 'filtered'};
    
    % Plot outliers with non-physiological interval lengths
    if (~isempty(outlier_idx1))
        plot(tnn(outlier_idx1), nni(outlier_idx1), 'kx'); % outliers as x's
        legend_labels{end+1} = 'outliers1';
    end
    
    % Plot outliers found by averaging
    if (~isempty(outlier_idx2))
        plot(tnn(outlier_idx2), nni(outlier_idx2), 'ro'); % outliers as circles
        legend_labels{end+1} = 'outliers2';
    end

    % plot averages
    plot(tnn, nni_lp, 'k', tnn, nni_lp.*(1.0-win_percent/100), 'k--', tnn, nni_lp.*(1.0+win_percent/100), 'k--');
    legend_labels = [legend_labels, {'average', 'thresholds'}];
    legend(legend_labels);
end

end

