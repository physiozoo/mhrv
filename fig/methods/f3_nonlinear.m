close all;
output_dir = ['fig' filesep 'out'];

% Load human parameters
rhrv_load_params('human');

rec_name = ['db' filesep 'fantasia' filesep 'f1y06']; from = 0*60*250 + 1; to = 120*60*250;

% Calculate intervals
[rri, trr] = ecgrr(rec_name, 'from', from, 'to', to);
[nni, tnn] = filtrr(rri, trr);

% Calculate nonlinear metrics
[~, plot_data] = hrv_nonlinear(nni);

%% Plots
fig_dfa = figure('Name', plot_data.dfa.name);
plot_dfa_fn(gca, plot_data.dfa);

fig_beta = figure('Name', plot_data.beta.name);
plot_hrv_nl_beta(gca, plot_data.beta);

fig_mse = figure('Name', plot_data.mse.name);
plot_mse(gca, plot_data.mse, 'legend_name', 'Original', 'show_sampen', false);

% Also plot the MSE of a shuffled version of the signal for comparison
nni_shuffled = nni(randperm(length(nni)));
[~, ~, plot_data_shuf] = mse(nni_shuffled);
plot_mse(gca, plot_data_shuf, 'linespec', '--r^', 'show_sampen', false, 'legend_name', 'Shuffled', 'clear', false);
lgd = legend(gca);

%% Print to file
width  = 18; % cm
height = 9; % cm

rec_split = strsplit(rec_name, filesep);
filename_prefix = [output_dir filesep rec_split{end-1} '_' rec_split{end} '_'];

fig_print(fig_dfa, [filename_prefix 'dfa'], 'width', width, 'height', height);
fig_print(fig_mse, [filename_prefix 'mse'], 'width', width, 'height', height);
fig_print(fig_beta, [filename_prefix 'beta'], 'width', width, 'height', height);