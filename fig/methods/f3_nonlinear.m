close all;

rec_name = ['db' filesep 'fantasia' filesep 'f1y06']; from = 0*60*250 + 1; to = 120*60*250;

% Calculate intervals
[nni, tnn, rri, trr] = ecgnn(rec_name, 'plot', false, 'from', from, 'to', to, ...
                            'filter_gqpost', false, 'filter_lowpass', true, 'filter_poincare', true);

%% Poincare
[sd1, sd2, outliers] = poincare(rri, 'plot', true);
fig_poincare = gcf;

%% DFA (alpha)
[DFA_n, DFA_Fn] = dfa(tnn, nni, 'n_incr', 2, 'plot', true);
fig_dfa = gcf;

%% MSE
[mse_values, scale_axis] = mse(nni, 'plot', true);
fig_mse = gcf;

%% Beta
[ ~, pxx, f_axis ] = hrv_freq(nni, tnn, 'methods', {'ar'}, 'window_minutes', 30);

% Fit a line and get the slope
beta_band_idx = find(f_axis >= 0.005 & f_axis <= 0.042);
pxx_log = log10(pxx(beta_band_idx));
f_axis_log = log10(f_axis(beta_band_idx));
pxx_fit_beta = polyfit(f_axis_log, pxx_log, 1);
hrv_nl.beta = pxx_fit_beta(1);
beta_line = pxx_fit_beta(1) * f_axis_log + pxx_fit_beta(2);

fig_beta = figure;
loglog(f_axis(beta_band_idx), pxx(beta_band_idx), 'bo-'); hold on; grid on;
loglog(10.^f_axis_log, 10.^beta_line, 'Color', 'magenta', 'LineStyle', ':', 'LineWidth', 4);
xlabel('log(frequency [hz])'); ylabel('log(PSD [s^2/Hz])');
legend('PSD', ['\beta = ' num2str(hrv_nl.beta)], 'Location', 'southwest');
axis tight;

%% Print to file

width  = 18; % cm
height = 9; % cm

rec_split = strsplit(rec_name, filesep);
filename_prefix = [rec_split{end-1} '_' rec_split{end} '_'];

fig_print(fig_poincare, [filename_prefix 'poincare'], 'width', width, 'height', height);
fig_print(fig_dfa, [filename_prefix 'dfa'], 'width', width, 'height', height);
fig_print(fig_mse, [filename_prefix 'mse'], 'width', width, 'height', height);
fig_print(fig_beta, [filename_prefix 'beta'], 'width', width, 'height', height);