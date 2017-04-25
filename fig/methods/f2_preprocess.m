close all;
output_dir = ['fig' filesep 'out'];

% Load human parameters
rhrv_load_params human;

% Specify record
rec_name = ['db' filesep 'fantasia' filesep 'f1y06']; from = 0*60*250 + 1; to = 120*60*250;

% Calculate and filter intervals
[rri, trr, plot_data_ecgrr] = ecgrr(rec_name, 'from', from, 'to', to);
[nni, tnn, plot_data_filtrr] = filtrr(rri, trr);

% Freq-domain of orginal intervals
[~, ~, ~, plot_data_freq_orig] = hrv_freq(rri);

% Freq-domain of filtered intervals
[~, ~, ~, plot_data_freq_filt] = hrv_freq(nni);

%% Create figures
fig_ecg = figure('Name', plot_data_ecgrr.name); ax_ecg = gca;
fig_filtrr = figure('Name', plot_data_filtrr.filtrr.name); ax_filtrr = gca;
fig_poincare = figure('Name', plot_data_filtrr.poincare.name); ax_poincare = gca;
fig_freq_orig = figure('Name', [plot_data_freq_orig.name ' (original)']); ax_freq_orig = gca;
fig_freq_filt = figure('Name', [plot_data_freq_filt.name ' (filtered)']); ax_freq_filt = gca;

plot_ecgrr(ax_ecg, plot_data_ecgrr);
plot_filtrr(ax_filtrr, plot_data_filtrr.filtrr);
plot_poincare_ellipse(ax_poincare, plot_data_filtrr.poincare);
plot_hrv_freq_spectrum(ax_freq_orig, plot_data_freq_orig);
plot_hrv_freq_spectrum(ax_freq_filt, plot_data_freq_filt);

%% Print to file
% A4 width x height is 210x297 mm
% Latex default text height: about 20cm
% Latex default text width: about 12cm

width  = 18; % cm
height = 9; % cm
rec_split = strsplit(rec_name, filesep);
filename_prefix = [output_dir filesep rec_split{end-1} '_' rec_split{end} '_'];

xlim(findobj(fig_ecg, 'type', 'axes'), 4310 + [0, 10]);
xlim(findobj(fig_filtrr, 'type', 'axes'), 4280 + [0, 50]);
set(findobj(fig_ecg, 'type','legend'), 'location', 'southwest');
set(findobj(fig_filtrr, 'type','legend'), 'location', 'southwest');

fig_print(fig_ecg, [filename_prefix 'ecg'], 'width', width, 'height', height);
fig_print(fig_poincare, [filename_prefix 'poincare'], 'width', width, 'height', height);
fig_print(fig_filtrr, [filename_prefix 'filtered_intervals'], 'width', width, 'height', height);
fig_print(fig_freq_orig, [filename_prefix 'original_spectrum'], 'width', width, 'height', height);
fig_print(fig_freq_filt, [filename_prefix 'filtered_spectrum'], 'width', width, 'height', height);
