close all;

width = 21; % cm
height = 8; % cm

rec_name = ['db' filesep 'mitdb' filesep '105'];

% Calculate intervals
[nni, tnn, rri, trr] = ecgnn(rec_name, 'plot', false);

% Poincare
[sd1, sd2, outliers] = poincare(rri, 'plot', true, 'r_factor', 2.25);
fig_poincare = gcf;

% DFA (alpha)
[DFA_n, DFA_Fn] = dfa(tnn, nni, 'n_incr', 2, 'plot', true);
fig_dfa = gcf;

% MSE
[mse_values, scale_axis] = mse(nni, 'plot', true);
fig_mse = gcf;

%% Print to file

rec_split = strsplit(rec_name, filesep);
filename_prefix = [rec_split{end-1} '_' rec_split{end} '_'];

fig_print(fig_poincare, [filename_prefix 'poincare'], 'width', width, 'height', height);
fig_print(fig_dfa, [filename_prefix 'dfa'], 'width', width, 'height', height);
fig_print(fig_mse, [filename_prefix 'mse'], 'width', width, 'height', height);