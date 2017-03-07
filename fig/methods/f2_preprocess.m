close all;

width = 21; % cm
height = 8; % cm

rec_name = ['db' filesep 'mitdb' filesep '105'];

% Plot preprocessed intervals
[nni, tnn, rri, trr] = ecgnn(rec_name, 'plot', true);
fig_processed_intervals = gcf;

% Plot freq-domain of orginal intervals
hrv_freq(rri, trr, 'plot', true);
fig_freq_orig = gcf;

% Plot freq-domain of preprocessed intervals
hrv_freq(nni, tnn, 'plot', true);
fig_freq_processed = gcf;

%% Print to file

rec_split = strsplit(rec_name, filesep);
filename_prefix = [rec_split{end-1} '_' rec_split{end} '_'];

% fig_print(fig_processed_intervals, [filename_prefix 'preprocessed_intervals'], 'width', width, 'height', height);
% fig_print(fig_freq_orig, [filename_prefix 'original_spectrum'], 'width', width, 'height', height);
% fig_print(fig_freq_processed, [filename_prefix 'preprocessed_spectrum'], 'width', width, 'height', height);
