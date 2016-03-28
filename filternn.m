function [ tnn_filtered, nni_filtered ] = filternn( tnn, nni, varargin )
%FILTERNN Filters NN intervals to remove possible outliers
%   Performs filtering of NN intervals using an averaging filter.
%   If an interval is greater (abs) than X percent of the average in a
%   window around it, excludes the interval. The window average is
%   calculated without the sample itself.
%
%   Based on:
%   1) PhysioNet HRV toolkit: https://physionet.org/tutorials/hrv-toolkit/
%   2) Moody, G. B. (1993). Spectral analysis of heart rate without resampling.
%      Computers in Cardiology 1993, Proceedings., (1), 7?10.
%      Retrieved from http://ieeexplore.ieee.org/xpls/abs_all.jsp?arnumber=378302

%% === Input

% Defaults
DEFAULT_WIN_SAMPLES = 20; % samples
DEFAULT_WIN_PERCENT = 20; % percentage [0-100]

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('tnn', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('nni', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('win_samples', DEFAULT_WIN_SAMPLES, @isnumeric);
p.addParameter('win_percent', DEFAULT_WIN_PERCENT, @(x) x >= 0 && x <= 100);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(tnn, nni, varargin{:});
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

%% Filter interval in window

% Filter the NN intervals with a moving average window
b_fir = 1/(2 * win_samples) .* [ones(win_samples,1); 0; ones(win_samples,1)];
nni_lp = filtfilt(b_fir, 1, nni); % using filtfilt for zero-phase

% Find and remove outliers
outlier_idx = find( abs(nni - nni_lp) > (win_percent/100) .* nni_lp );
nni_filtered(outlier_idx) = [];
tnn_filtered(outlier_idx) = [];

%% Plot if no output args
if (should_plot)
    fontsize = 14;
    markersize = 10.0;
    set(0,'DefaultAxesFontSize',fontsize);
    figure; hold on; grid on;
    xlabel('time [s]'); ylabel('RR Interval length [s]');

    % Plot original intervals
    plot(tnn, nni);
    legend_labels = {'RR intervals'};

    % Plot outliers found by averaging
    if (~isempty(outlier_idx))
        plot(tnn(outlier_idx), nni(outlier_idx), 'ko', 'MarkerSize', markersize);
        legend_labels{end+1} = 'filtered intervals';
    end

    % Plot window average and thresholds
    lower_threshold = nni_lp.*(1.0-win_percent/100);
    upper_threshold = nni_lp.*(1.0+win_percent/100);
    plot(tnn, nni_lp, 'k', tnn, lower_threshold, 'k--', tnn, upper_threshold, 'k--');
    legend_labels = [legend_labels, {'window average', 'window threshold'}];
    
    legend(legend_labels);
end

end

