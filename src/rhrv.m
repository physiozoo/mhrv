function [ hrv_metrics ] = rhrv( rec_name, varargin )
%RHRV Heart Rate Variability metrics
% Analyzes an ECG signal, detects and filters R-peaks and calculates various heart-rate variability
% (HRV) metrics on them.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - window_minutes: Split ECG signal into windows of the specified length (in minutes)
%                             and perform the analysis on each window separately.
%           - window_index_offset: Number of windows to skip from the beginning.
%           - window_index_limit: Maximal number of windows to process. Combined with the above,
%                                 this allows control of which window to start from and how many
%                                 windows to process from there.
%           - params: Name of rhrv defaults file to use (e.g. 'canine'). Default '', i.e. no
%                     parameters file will be loaded.
%           - plot: true/false whether to generate plots. Defaults to true if no output arguments
%                   were specified.
%   Outputs:
%       - hrv_metrics: A table where each row is a window and each column is an HRV metrics that was
%                      calculated in that window.

%% Make sure environment is set up
rhrv_init --close;

%% Handle input

% Defaults
DEFAULT_ECG_CHANNEL = [];
DEFAULT_WINDOW_MINUTES = Inf;
DEFAULT_WINDOW_INDEX_LIMIT = Inf;
DEFAULT_WINDOW_INDEX_OFFSET = 0;
DEFAULT_PARAMS = '';

% Define input
p = inputParser;

p.addRequired('rec_name', @isrecord);
p.addParameter('ecg_channel', DEFAULT_ECG_CHANNEL, @(x) isnumeric(x) && isscalar(x));
p.addParameter('window_minutes', DEFAULT_WINDOW_MINUTES, @(x) isnumeric(x) && numel(x) < 2 && x > 0);
p.addParameter('window_index_limit', DEFAULT_WINDOW_INDEX_LIMIT, @(x) isnumeric(x) && numel(x) < 2 && x > 0);
p.addParameter('window_index_offset', DEFAULT_WINDOW_INDEX_OFFSET, @(x) isnumeric(x) && numel(x) < 2 && x >= 0);
p.addParameter('params', DEFAULT_PARAMS, @ischar);
p.addParameter('plot', nargout == 0,  @(x) isscalar(x) && islogical(x));

% Get input
p.parse(rec_name, varargin{:});
ecg_channel = p.Results.ecg_channel;
params = p.Results.params;
window_minutes = p.Results.window_minutes;
window_index_limit = p.Results.window_index_limit;
window_index_offset = p.Results.window_index_offset;
should_plot = p.Results.plot;

% Load user-specified default parameters
if ~isempty(params)
    rhrv_load_params(params);
end

%% Process ECG Signal
% Save processing start time
t0 = cputime;

% Get data about the ECG channel in the signal
[default_ecg_channel, ecg_Fs, ecg_N] = get_signal_channel(rec_name);
if isempty(ecg_channel)
    if isempty(default_ecg_channel)
        error('No ECG channel found in record %s', rec_name);
    else
        ecg_channel = default_ecg_channel;
    end
end
fprintf('[%.3f] >> rhrv: Processing ECG signal from record %s (ch. %d)...\n', cputime-t0, rec_name, ecg_channel);

% Length of signal in seconds
t_max = ecg_N / ecg_Fs;

% Duration of signal
duration_h  = mod(floor(t_max / 3600), 60);
duration_m  = mod(floor(t_max / 60), 60);
duration_s  = mod(floor(t_max), 60);
duration_ms = floor(mod(t_max, 1)*1000);
fprintf('[%.3f] >> rhrv: Signal duration: %02d:%02d:%02d.%03d [HH:mm:ss.ms]\n', cputime-t0,...
        duration_h, duration_m, duration_s, duration_ms);

% Length of each window in seconds and samples (make sure the window is not longer than the signal)
t_win = min([window_minutes * 60, t_max]);
window_samples = t_win * ecg_Fs;

% Number of windows
num_win = floor(ecg_N / window_samples);

% Account for window index offset and limit
if (window_index_offset >= num_win)
    error('Invalid window index offset: was %d, but there are only %d %d-minute windows',...
           window_index_offset, num_win, window_minutes);
end
window_max_index = min(num_win, window_index_offset + window_index_limit) - 1;

% Output initialization
hrv_metrics_tables = cell(num_win, 1);
plot_datas = cell(num_win, 1);

% Loop over all windows
for curr_win_idx = window_index_offset : window_max_index
    fprintf('[%.3f] >> rhrv: Analyzing window %d of %d...\n', cputime-t0, curr_win_idx+1, num_win);

    % Calculate sample indices of the current window
    window_start_sample = curr_win_idx * window_samples + 1;
    window_end_sample   = window_start_sample + window_samples - 1;

    % Read & process RR intervals from ECG signal
    fprintf('[%.3f] >> rhrv: [%d/%d] Detecting QRS end RR intervals...\n', cputime-t0, curr_win_idx+1, num_win);
    [rri_window, trr_window, pd_ecgrr] = ecgrr(rec_name, 'ecg_channel', ecg_channel, 'from', window_start_sample, 'to', window_end_sample);

    % Filter RR intervals to produce NN intervals
    fprintf('[%.3f] >> rhrv: [%d/%d] Filtering RR intervals...\n', cputime-t0, curr_win_idx+1, num_win);
    [nni_window, tnn_window, pd_filtrr] = filtrr(rri_window, trr_window);

    if (isempty(nni_window))
        warning('[%.3f] >> rhrv: [%d/%d] No R-peaks detected in window, skipping\n', cputime-t0, curr_win_idx+1, num_win);
        continue;
    end

    fprintf('[%.3f] >> rhrv: [%d/%d] %d NN intervals, %d RR intervals were filtered out\n',...
            cputime-t0, curr_win_idx+1, num_win, length(nni_window), length(trr_window)-length(tnn_window));

    % Time Domain metrics
    fprintf('[%.3f] >> rhrv: [%d/%d] Calculating time-domain metrics...\n', cputime-t0, curr_win_idx+1, num_win);
    [hrv_td, pd_time ]= hrv_time(nni_window);

    % Freq domain metrics
    fprintf('[%.3f] >> rhrv: [%d/%d] Calculating frequency-domain metrics...\n', cputime-t0, curr_win_idx+1, num_win);
    [ hrv_fd, ~, ~,  pd_freq ] = hrv_freq(nni_window);

    % Non linear metrics
    fprintf('[%.3f] >> rhrv: [%d/%d] Calculating nonlinear metrics...\n', cputime-t0, curr_win_idx+1, num_win);
    [hrv_nl, pd_nl] = hrv_nonlinear(nni_window);

    % Update metrics table
    intervals_count = table(length(rri_window),length(nni_window),'VariableNames',{'RR','NN'});
    intervals_count.Properties.VariableUnits = {'1','1'};
    intervals_count.Properties.VariableDescriptions = {'Number of RR intervals','Number of NN intervals'};
    
    hrv_metrics_tables{curr_win_idx+1} = [intervals_count, hrv_td, hrv_fd, hrv_nl];

    % Save plot data
    plot_datas{curr_win_idx+1}.ecgrr = pd_ecgrr;
    plot_datas{curr_win_idx+1}.filtrr = pd_filtrr;
    plot_datas{curr_win_idx+1}.time = pd_time;
    plot_datas{curr_win_idx+1}.freq = pd_freq;
    plot_datas{curr_win_idx+1}.nl = pd_nl;
end

%% Create output table
fprintf('[%.3f] >> rhrv: Building output table...\n', cputime-t0);

% Concatenate the tables from each window into one final table
hrv_metrics = table;
for ii = 1:num_win
    hrv_metrics = [hrv_metrics; hrv_metrics_tables{ii}];
end
hrv_metrics.Properties.Description = sprintf('HRV metrics for %s', rec_name);

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

%% Display output if no output args
if (nargout == 0)
    disp(hrv_metrics);
end

if (should_plot)
    fprintf('[%.3f] >> rhrv: Generating plots...\n', cputime-t0);
    [~, filename] = fileparts(rec_name);
    for ii = 1:length(plot_datas)

        % Might have empty cells in plot_datas because we don't always calculate metrics for all
        % windows (depends on user input).
        if isempty(plot_datas{ii})
            continue;
        end

        window = sprintf('%d/%d', ii, length(plot_datas));
        
        fig_name = sprintf('[%s %s] %s', filename, window, plot_datas{ii}.ecgrr.name);
        figure('NumberTitle','off', 'Name', fig_name);
        plot_ecgrr(gca, plot_datas{ii}.ecgrr);

        fig_name = sprintf('[%s %s] %s', filename, window, plot_datas{ii}.filtrr.filtrr.name);
        figure('NumberTitle','off', 'Name', fig_name);
        plot_filtrr(gca, plot_datas{ii}.filtrr.filtrr);

        % If using poincare filter, plot from that, otherwize plot it from the NL metrics
        if rhrv_default('filtrr.filter_poincare')
            poincare_pd = plot_datas{ii}.filtrr.poincare;
        else
            poincare_pd = plot_datas{ii}.nl.poincare;
        end
        fig_name = sprintf('[%s %s] %s', filename, window, poincare_pd.name);
        figure('NumberTitle','off', 'Name', fig_name);
        plot_poincare_ellipse(gca, poincare_pd);

        fig_name = sprintf('[%s %s] %s', filename, window, plot_datas{ii}.time.name);
        figure('NumberTitle','off', 'Name', fig_name);
        plot_hrv_time_hist(gca, plot_datas{ii}.time);

        fig_name = sprintf('[%s %s] %s', filename, window, plot_datas{ii}.freq.name);
        figure('NumberTitle','off', 'Name', fig_name);
        plot_hrv_freq_spectrum(gca, plot_datas{ii}.freq);

        fig_name = sprintf('[%s %s] %s', filename, window, plot_datas{ii}.nl.name);
        figure('NumberTitle','off', 'Name', fig_name);
        subax1 = subplot(3, 1, 1);
        plot_dfa_fn(subax1, plot_datas{ii}.nl.dfa);
        subax2 = subplot(3, 1, 2);
        plot_hrv_nl_beta(subax2, plot_datas{ii}.nl.beta);
        subax3 = subplot(3, 1, 3);
        plot_mse(subax3, plot_datas{ii}.nl.mse);
    end
end
fprintf('[%.3f] >> rhrv: Finished processing record %s.\n', cputime-t0, rec_name);

