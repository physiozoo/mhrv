function [ hrv_metrics, hrv_stats, plot_datas ] = mhrv( rec_name, varargin )
%Analyzes an ECG signal, detects and filters R-peaks and calculates various
%heart-rate variability (HRV) metrics on them.
%
%:param rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if
%   the record files (both 100.dat and 100.hea) are in a folder named 'db/mitdb'
%   relative to MATLABs pwd.
%
%:param varargin: Pass in name-value pairs to configure advanced options.
%
%   - ecg_channel: The channel number to use (in case the record has more
%     than one). If not provided, mhrv will attempt to use the first channel that
%     has ECG data.
%   - ann_ext: Specify an annotation file extention to use instead of loading
%     the record itself (.dat file). If provided, RR intervals will be loaded from
%     the annotation file instead of from the ECG.  Default: empty (don't use
%     annotation).
%   - window_minutes: Split ECG signal into windows of the specified length (in
%     minutes) and perform the analysis on each window separately.
%   - window_index_offset: Number of windows to skip from the beginning.
%   - window_index_limit: Maximal number of windows to process. Combined with the above,
%     this allows control of which window to start from and how many
%     windows to process from there.
%   - params: Name of mhrv defaults file to use (e.g. 'canine'). Default '', i.e. no
%     parameters file will be loaded. Alternatively, can also be a cell array
%     containing the exact arguments to pass to mhrv_load_params. This allows
%     overriding parameters from a script.
%   - transform_fn: A function handle to apply to the NN intervals before calculating
%     metrics. The function handle should accept one argument only, the NN
%     interval lengths.
%   - plot: true/false whether to generate plots. Defaults to true if no output arguments
%     were specified.
%
%:returns:
%   - hrv_metrics: A table where each row is a window and each column is an
%     HRV metrics that was calculated in that window.
%   - hrv_stats: A table containing various statistics about each metric,
%     calculated over all windows.
%   - plot_datas: Cell array containing the plot_data structs for each window.
%

import mhrv.defaults.*
import mhrv.ecg.*
import mhrv.hrv.*
import mhrv.rri.*
import mhrv.util.*
import mhrv.wfdb.*
import mhrv.plots.*

%% Handle input

% Defaults
DEFAULT_ECG_CHANNEL = [];
DEFAULT_ANN_EXT = '';
DEFAULT_WINDOW_MINUTES = Inf;
DEFAULT_WINDOW_INDEX_LIMIT = Inf;
DEFAULT_WINDOW_INDEX_OFFSET = 0;
DEFAULT_PARAMS = '';

% Define input
p = inputParser;

p.addRequired('rec_name');
p.addParameter('ann_ext', DEFAULT_ANN_EXT, @(x) ischar(x));
p.addParameter('ecg_channel', DEFAULT_ECG_CHANNEL, @(x) isnumeric(x) && isscalar(x));
p.addParameter('window_minutes', DEFAULT_WINDOW_MINUTES, @(x) isnumeric(x) && numel(x) < 2 && x > 0);
p.addParameter('window_index_limit', DEFAULT_WINDOW_INDEX_LIMIT, @(x) isnumeric(x) && numel(x) < 2 && x > 0);
p.addParameter('window_index_offset', DEFAULT_WINDOW_INDEX_OFFSET, @(x) isnumeric(x) && numel(x) < 2 && x >= 0);
p.addParameter('params', DEFAULT_PARAMS, @(x) ischar(x)||iscell(x));
p.addParameter('transform_fn', [], @(x) isempty(x)||isa(x,'function_handle'));
p.addParameter('plot', nargout == 0,  @(x) isscalar(x) && islogical(x));

% Get input
p.parse(rec_name, varargin{:});
ann_ext = p.Results.ann_ext;
ecg_channel = p.Results.ecg_channel;
window_minutes = p.Results.window_minutes;
window_index_limit = p.Results.window_index_limit;
window_index_offset = p.Results.window_index_offset;
params = p.Results.params;
transform_fn = p.Results.transform_fn;
should_plot = p.Results.plot;


%% Make sure toolbox is set up

% Find the mhrv_init script path (we don't assume it's in the matlab path until it's run)
[curr_folder, ~, ~] = file_parts(mfilename('fullpath'));
[parent_folder, ~, ~] = file_parts(curr_folder);
init_path = [parent_folder filesep 'mhrv_init.m'];

% Run mhrv_init. This won't actually do anything if it has already run before.
run(init_path);

%% Load user-specified default parameters
if ~isempty(params)
    if iscell(params)
        mhrv_load_defaults(params{:});
    else
        mhrv_load_defaults(params);
    end
end

%% Process ECG Signal or Annotations

%% Make sure rec_name is valid - has either data or annotation
if isempty(ann_ext)
    if ~isrecord(rec_name)
        error('Invalid record name %s', rec_name);
    end
    rr_intervals_source = 'ECG';
else
    if ~isrecord(rec_name, ann_ext)
        error('Invalid record name %s: Can''t find annotator %s', rec_name, ann_ext);
    end
    rr_intervals_source = sprintf('annotator (%s)', ann_ext);
end

% Save processing start time
t0 = cputime;

% Get data about the signal from the header
header_info = wfdb_header(rec_name);
ecg_Fs = header_info.Fs;
ecg_N = header_info.N_samples;

if ecg_N == 0
    if isempty(ann_ext)
        warning('Number of samples in the record wasn''t specified in the header file. Can''t calculate duration or split into windows.');
    else
        % This header file contains no channels, so the number of samples
        % is zero. Since we have an annotation file, we'll determine the
        % number of samples from it.
        ann = rdann(rec_name, ann_ext);
        ecg_N = double(ann(end));

        % Set length of record based on it
        header_info.total_seconds = ecg_N / ecg_Fs;
        header_info.duration = seconds_to_hmsms(header_info.total_seconds);
    end
end

% Get ECG channel number
if isempty(ecg_channel)
    default_ecg_channel = get_signal_channel(rec_name, 'header_info', header_info);
    if isempty(default_ecg_channel) && isempty(ann_ext)
        error('No ECG channel found in record %s', rec_name);
    else
        ecg_channel = default_ecg_channel;
    end
end
fprintf('[%.3f] >> mhrv: Processing record %s (ch. %d)...\n', cputime-t0, rec_name, ecg_channel);

% Length of signal in seconds
t_max = floor(header_info.total_seconds);

% Duration of signal
duration = header_info.duration;
fprintf('[%.3f] >> mhrv: Signal duration: %02d:%02d:%02d.%03d [HH:mm:ss.ms]\n', cputime-t0,...
        duration.h, duration.m, duration.s, duration.ms);

% Length of each window in seconds and samples (make sure the window is not longer than the signal)
t_win = min([window_minutes * 60, t_max]);
window_samples = t_win * ecg_Fs;

% Number of windows
num_win = floor(ecg_N / window_samples);
if (isnan(num_win))
    % This can happen in some records where number of samples is not provided
    num_win = 1;
end

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
    fprintf('[%.3f] >> mhrv: Analyzing window %d of %d...\n', cputime-t0, curr_win_idx+1, num_win);

    % Calculate sample indices of the current window
    window_start_sample = curr_win_idx * window_samples + 1;
    window_end_sample   = window_start_sample + window_samples - 1;
    if (window_end_sample == 0); window_end_sample = []; end

    try
        % Read & process RR intervals from ECG signal
        fprintf('[%.3f] >> mhrv: [%d/%d] Detecting RR intervals from %s... ', cputime-t0, curr_win_idx+1, num_win, rr_intervals_source);
        [rri_window, trr_window, pd_ecgrr] = ecgrr(rec_name, 'header_info', header_info, 'ann_ext', ann_ext, 'ecg_channel', ecg_channel, 'from', window_start_sample, 'to', window_end_sample);
        fprintf('%d intervals detected.\n', length(trr_window));

        % Apply transform function if available
        if ~isempty(transform_fn)
            fprintf('[%.3f] >> mhrv: [%d/%d] Applying transform function %s...\n', cputime-t0, curr_win_idx+1, num_win, func2str(transform_fn));
            rri_window = transform_fn(rri_window);
            % Rebuild time axis because length of rri may have changed
            trr_window = [0; cumsum(rri_window(1:end-1))] + trr_window(1);
        end

        % Filter RR intervals to produce NN intervals
        fprintf('[%.3f] >> mhrv: [%d/%d] Removing ectopic intervals... ', cputime-t0, curr_win_idx+1, num_win);
        [nni_window, tnn_window, pd_filtrr] = filtrr(rri_window, trr_window);
        fprintf('%d intervals removed.\n', length(trr_window)-length(tnn_window));

        if (isempty(nni_window))
            fprintf(2, '[%.3f] >> mhrv: [%d/%d] No intervals detected in window, skipping\n', cputime-t0, curr_win_idx+1, num_win);
            continue;
        end

        % Time Domain metrics
        fprintf('[%.3f] >> mhrv: [%d/%d] Calculating time-domain metrics...\n', cputime-t0, curr_win_idx+1, num_win);
        [hrv_td, pd_time ]= hrv_time(nni_window);

        % Freq domain metrics
        fprintf('[%.3f] >> mhrv: [%d/%d] Calculating frequency-domain metrics...\n', cputime-t0, curr_win_idx+1, num_win);
        [hrv_fd, ~, ~,  pd_freq ] = hrv_freq(nni_window);

        % Non linear metrics
        fprintf('[%.3f] >> mhrv: [%d/%d] Calculating nonlinear metrics...\n', cputime-t0, curr_win_idx+1, num_win);
        [hrv_nl, pd_nl] = hrv_nonlinear(nni_window);

        % Heart rate fragmentation metrics
        fprintf('[%.3f] >> mhrv: [%d/%d] Calculating fragmentation metrics...\n', cputime-t0, curr_win_idx+1, num_win);
        hrv_frag = hrv_fragmentation(nni_window);
    catch e
        fprintf(2,'\n');
        fprintf(2,'[%.3f] >> mhrv: ERROR Analyzing window %d of %d in record %s:\n', cputime-t0, curr_win_idx+1, num_win, rec_name);
        fprintf(2,'%s\nskipping window...\n', e.message);
        continue;
    end

    % Update metrics table
    intervals_count = table(length(rri_window),length(nni_window),'VariableNames',{'RR','NN'});
    intervals_count.Properties.VariableUnits = {'n.u.','n.u.'};
    intervals_count.Properties.VariableDescriptions = {'Number of RR intervals','Number of NN intervals'};

    % Create and save the output table for the current window
    curr_win_table = [intervals_count, hrv_td, hrv_fd, hrv_nl, hrv_frag];
    curr_win_table.Properties.RowNames{1} = sprintf('%d', curr_win_idx+1);
    hrv_metrics_tables{curr_win_idx+1} = curr_win_table;

    % Save plot data
    plot_datas{curr_win_idx+1}.ecgrr = pd_ecgrr;
    plot_datas{curr_win_idx+1}.filtrr = pd_filtrr;
    plot_datas{curr_win_idx+1}.time = pd_time;
    plot_datas{curr_win_idx+1}.freq = pd_freq;
    plot_datas{curr_win_idx+1}.nl = pd_nl;
end

% Create full table
hrv_metrics = vertcat(hrv_metrics_tables{:});

if isempty(hrv_metrics)
    fprintf(2,'[%.3f] >> mhrv: ERROR: All windows failed analysis. Exiting...\n', cputime-t0);
    return;
end

hrv_metrics.Properties.Description = sprintf('HRV metrics for %s', rec_name);

% Remove empty entries from plot data (windows that were skipped and don't
% appear in the hrv metrics table).
nonempty_idx = cellfun(@(x) ~isempty(x), plot_datas);
plot_datas = plot_datas(nonempty_idx);

%% Create stats table
fprintf('[%.3f] >> mhrv: Building statistics table...\n', cputime-t0);
hrv_stats = table_stats(hrv_metrics);

%% Display output if no output args
if (nargout == 0)
    fprintf('[%.3f] >> mhrv: Displaying Results...\n', cputime-t0);
    % Display statistics if there is more than one window
    if (size(hrv_metrics,1) > 1)
        disp([hrv_metrics; hrv_stats]);
    else
        disp(hrv_metrics);
    end
end

if (should_plot)
    fprintf('[%.3f] >> mhrv: Generating plots...\n', cputime-t0);
    [~, filename] = file_parts(rec_name);
    for ii = 1:length(plot_datas)

        % Might have empty cells in plot_datas because we don't always calculate metrics for all
        % windows (depends on user input).
        if isempty(plot_datas{ii})
            continue;
        end

        window = sprintf('%d/%d', ii, length(plot_datas));

        % When using annotations, wont have ecgrr plot data
        if ~isempty(fieldnames(plot_datas{ii}.ecgrr))
            fig_name = sprintf('[%s %s] %s', filename, window, plot_datas{ii}.ecgrr.name);
            figure('NumberTitle','off', 'Name', fig_name);
            plot_ecgrr(gca, plot_datas{ii}.ecgrr);
        end

        fig_name = sprintf('[%s %s] %s', filename, window, plot_datas{ii}.filtrr.name);
        figure('NumberTitle','off', 'Name', fig_name);
        plot_filtrr(gca, plot_datas{ii}.filtrr);

        % Poincare plot
        poincare_pd = plot_datas{ii}.nl.poincare;
        fig_name = sprintf('[%s %s] %s', filename, window, poincare_pd.name);
        figure('NumberTitle','off', 'Name', fig_name);
        plot_poincare_ellipse(gca, poincare_pd);

        fig_name = sprintf('[%s %s] %s', filename, window, plot_datas{ii}.time.name);
        figure('NumberTitle','off', 'Name', fig_name);
        plot_hrv_time_hist(gca, plot_datas{ii}.time);

        fig_name = sprintf('[%s %s] %s', filename, window, plot_datas{ii}.freq.name);
        figure('NumberTitle','off', 'Name', fig_name);
        plot_hrv_freq_spectrum(gca, plot_datas{ii}.freq, 'detailed_legend', true, 'peaks', true);

        fig_name = sprintf('[%s %s] %s', filename, window, plot_datas{ii}.nl.name);
        figure('NumberTitle','off', 'Name', fig_name);
        subax1 = subplot(3, 1, 1);
        plot_dfa_fn(subax1, plot_datas{ii}.nl.dfa);
        subax2 = subplot(3, 1, 2);
        plot_hrv_freq_beta(subax2, plot_datas{ii}.freq);
        subax3 = subplot(3, 1, 3);
        plot_mse(subax3, plot_datas{ii}.nl.mse);
    end
end
fprintf('[%.3f] >> mhrv: Finished processing record %s.\n', cputime-t0, rec_name);

