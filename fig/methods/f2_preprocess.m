close all;

width = 21; % cm
height = 8; % cm

% Plot preprocessed intervals
[nni, tnn, rri, trr] = ecgnn('db/mitdb/105');
[tnn_filtered, nni_filtered] = filternn(tnn,nni, 'plot', true);
fig_print(gcf, 'mitdb105_preprocessed_intervals', 'width', width, 'height', height);

% Plot freq-domain of orginal intervals
hrv_freq(nni, tnn, 'plot', true);
fig_print(gcf, 'mitdb105_original_spectrum', 'width', width, 'height', height);

% Plot freq-domain of preprocessed intervals
hrv_freq(nni_filtered, tnn_filtered, 'plot', true);
fig_print(gcf, 'mitdb105_preprocessed_spectrum', 'width', width, 'height', height);