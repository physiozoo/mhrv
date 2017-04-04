close all;
output_dir = ['fig' filesep 'out'];

% Specify record
rec_name = ['db' filesep 'fantasia' filesep 'f1y06']; from = 0*60*250 + 1; to = 120*60*250;

% Plot preprocessed intervals
[nni, tnn, rri, trr] = ecgnn(rec_name, 'plot', true, 'from', from, 'to', to, ...
                            'filter_gqpost', false, 'filter_lowpass', true, 'filter_poincare', true);

fig_poincare = findobj(0, 'type', 'figure', 'number', 1);
fig_ecg = findobj(0, 'type', 'figure', 'number', 2);
fig_processed_intervals = findobj(0, 'type', 'figure', 'number', 3);

% Plot freq-domain of orginal intervals
hrv_freq(rri, trr, 'plot', true, 'window_minutes', 5);
fig_freq_orig = gcf;

% Plot freq-domain of preprocessed intervals
hrv_freq(nni, tnn, 'plot', true, 'window_minutes', 5);
fig_freq_processed = gcf;

%% Print to file
% A4 width x height is 210x297 mm
% Latex default text height: about 20cm
% Latex default text width: about 12cm

width  = 18; % cm
height = 9; % cm

rec_split = strsplit(rec_name, filesep);
filename_prefix = [output_dir filesep rec_split{end-1} '_' rec_split{end} '_'];


xlim(findobj(fig_ecg, 'type', 'axes'), 4310 + [0, 10]);
xlim(findobj(fig_processed_intervals, 'type', 'axes'), 4280 + [0, 50]);
set(findobj(fig_ecg, 'type','legend'), 'location', 'southwest');
set(findobj(fig_processed_intervals, 'type','legend'), 'location', 'southwest');

fig_print(fig_ecg, [filename_prefix 'ecg'], 'width', width, 'height', height);
fig_print(fig_poincare, [filename_prefix 'poincare'], 'width', width, 'height', height);

fig_print(fig_processed_intervals, [filename_prefix 'preprocessed_intervals'], 'width', width, 'height', height);
fig_print(fig_freq_orig, [filename_prefix 'original_spectrum'], 'width', width, 'height', height);
fig_print(fig_freq_processed, [filename_prefix 'preprocessed_spectrum'], 'width', width, 'height', height);
