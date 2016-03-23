function [ hrv_metrics ] = rhrv( rec_name, varargin )
%RHRV Heart Rate Variability metrics
%   Detailed explanation goes here

close all;

%% === Input
% Defaults
DEFAULT_WINDOW_MINUTES = [];

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('window_minutes', DEFAULT_WINDOW_MINUTES, @(x) isnumeric(x) && numel(x) < 2);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
window_minutes = p.Results.window_minutes;
should_plot = p.Results.plot;

%% === Calculate NN intervals
[ nni, tnn, rri, ~ ] = ecgnn(rec_name, 'gqpost', true);

%% === Pre process intervals to remove outliers
[ tnn_filtered, nni_filtered ] = filternn(tnn, nni, 'plot', should_plot);

%% === Break into windows

% Set a window on the entire signal in case no window is needed, and convert window size to seconds
if (isempty(window_minutes))
    window_seconds = tnn_filtered(end);
else
    window_seconds = window_minutes * 60;
end

% Output table
hrv_metrics = table;

% Loop over all windows
curr_win_idx = [0, 1];
while true
    % Calculate time range of the current window and exit loop if the window "exited" the signal.
    curr_win = curr_win_idx * window_seconds; % [min, max] times of the window
    if (curr_win(2) > tnn_filtered(end)); break; end;

    window_samples_idx = find(tnn_filtered >= curr_win(1) & tnn_filtered <= curr_win(2));
    tnn_window = tnn_filtered(window_samples_idx);
    nni_window = nni_filtered(window_samples_idx);

    %% === Non linear metrics
    [hrv_nl] = hrv_nonlinear(nni_window, tnn_window, 'plot', should_plot);

    %% === Time Domain metrics
    hrv_td = hrv_time(nni_window);

    %% === Freq domain metrics
    [ hrv_fd, ~, ~ ] = hrv_freq(nni_window, tnn_window, 'method', 'lomb', 'plot', should_plot);

    %% === Create metrics table
    curr_metrics = [struct2table(hrv_td), struct2table(hrv_fd), struct2table(hrv_nl)];
    hrv_metrics = [hrv_metrics; curr_metrics];
    curr_win_idx = curr_win_idx + 1;
end

%% === Set table output rows

% Add an average values row if there is more than one window
[num_windows, ~] = size(hrv_metrics);
if (num_windows > 1)
    mean_values = num2cell(mean(hrv_metrics{:, 1:end}));
    mean_table = table(mean_values{1:end});
    mean_table.Properties.VariableNames = hrv_metrics.Properties.VariableNames;
    hrv_metrics = [hrv_metrics; mean_table];
end

row_names = cellstr(num2str(transpose(1:num_windows)));
row_names{end+1} = 'Avg.';
hrv_metrics.Properties.RowNames = row_names;

%% === Display output if no output args
if (nargout == 0)   
    % Print some of the HRV metrics to user
    disp(hrv_metrics(:, {'AVNN','SDNN','RMSSD','pNN50','ULF_to_TOT','VLF_to_TOT','LF_to_TOT','HF_to_TOT','alpha1','alpha2','beta'}));
end
