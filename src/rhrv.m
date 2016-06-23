function [ hrv_metrics ] = rhrv( rec_name, varargin )
%RHRV Heart Rate Variability metrics
%   Detailed explanation goes here

close all;

%% === Input
% Defaults
DEFAULT_WINDOW_MINUTES = Inf;
DEFAULT_SHOULD_PREPROCESS = true;
DEFAULT_GQCONF = 'cfg/gqrs.default.conf';

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('window_minutes', DEFAULT_WINDOW_MINUTES, @(x) isnumeric(x) && numel(x) < 2);
p.addParameter('should_preprocess', DEFAULT_SHOULD_PREPROCESS, @(x) isscalar(x) && islogical(x));
p.addParameter('gqconf', DEFAULT_GQCONF, @isstr);
p.addParameter('plot', nargout == 0,  @(x) isscalar(x) && islogical(x));

% Get input
p.parse(rec_name, varargin{:});
should_preprocess = p.Results.should_preprocess;
window_minutes = p.Results.window_minutes;
gqconf = p.Results.gqconf;
should_plot = p.Results.plot;

% Save processing start time
t0 = cputime;

%% === Calculate NN intervals
fprintf('[%.3f] >> rhrv: Reading ECG signal from record %s...\n', cputime-t0, rec_name);
[ nni, tnn, rri, ~ ] = ecgnn(rec_name, 'gqpost', true, 'gqconf', gqconf, 'use_rqrs', true);

fprintf('[%.3f] >> rhrv: Signal duration: %f [min] (%d samples)\n', cputime-t0, tnn(end)/60, length(tnn));

%% === Pre process intervals to remove outliers
if (should_preprocess)
    fprintf('[%.3f] >> rhrv: Pre-processing signal...\n', cputime-t0);
    [ tnn_filtered, nni_filtered ] = filternn(tnn, nni, 'plot', should_plot);

    fprintf('[%.3f] >> rhrv: %d intervals were filtered out\n', cputime-t0, length(tnn)-length(tnn_filtered));
else
    tnn_filtered = tnn; nni_filtered = nni;
end

%% === Break into windows

% Convert window size to seconds, and make sure the windw isn't longer than the signal itself
t_max = tnn_filtered(end);
t_win = min([window_minutes * 60, t_max]);
num_win = floor(t_max / t_win);

% Output initialization
hrv_metrics_tables = cell(num_win, 1);

% Loop over all windows
parfor curr_win_idx = 0:(num_win-1)
    fprintf('[%.3f] >> rhrv: Analyzing window %d of %d...\n', cputime-t0, curr_win_idx+1, num_win);

    % Calculate time range of the current window
    t_win_min = curr_win_idx * t_win;
    t_win_max = (curr_win_idx+1) * t_win;

    % Get the samples that fall in the window and their times
    [window_samples_idx_low, window_samples_idx_high] = findInSorted(tnn_filtered, [t_win_min, t_win_max]);
    window_samples_idx = window_samples_idx_low:window_samples_idx_high;
    tnn_window = tnn_filtered(window_samples_idx);
    nni_window = nni_filtered(window_samples_idx);

    %% === Non linear metrics
    hrv_nl = hrv_nonlinear(nni_window, tnn_window, 'plot', should_plot);

    %% === Time Domain metrics
    hrv_td = hrv_time(nni_window);

    %% === Freq domain metrics
    [ hrv_fd, ~, ~ ] = hrv_freq(nni_window, tnn_window, 'method', 'lomb', 'plot', should_plot);

    %% === Create metrics table
    hrv_metrics_tables{curr_win_idx+1} = [struct2table(hrv_td), struct2table(hrv_fd), struct2table(hrv_nl)];
end

%% === Create output table
fprintf('[%.3f] >> rhrv: Building output table...\n', cputime-t0);

% Concatenate the tables from each window into one final table
hrv_metrics = table;
for ii = 1:num_win
    hrv_metrics = [hrv_metrics; hrv_metrics_tables{ii}];
end

% Add an average values row if there is more than one window
[num_windows, ~] = size(hrv_metrics);
row_names = cellstr(num2str(transpose(1:num_windows)));
if (num_windows > 1)
    mean_values = num2cell(mean(hrv_metrics{:, 1:end}));
    mean_table = table(mean_values{1:end});
    mean_table.Properties.VariableNames = hrv_metrics.Properties.VariableNames;
    hrv_metrics = [hrv_metrics; mean_table];
    row_names{end+1} = 'Avg.';
end

% Set the row names of the final table
hrv_metrics.Properties.RowNames = row_names;

%% === Display output if no output args
if (nargout == 0)
    % Print some of the HRV metrics to user
    disp(hrv_metrics(:,...
        {'AVNN','SDNN','RMSSD','pNN50',...
         'LF_to_TOT','HF_to_TOT', 'LF_to_HF',...
         'alpha1','alpha2','beta', 'mse_a', 'mse_b'}));
end
if (should_plot)
    tilefigs;
end
fprintf('[%.3f] >> rhrv: Finished processing record %s.\n', cputime-t0, rec_name);

