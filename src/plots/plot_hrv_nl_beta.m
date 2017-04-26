function [] = plot_hrv_nl_beta(ax, plot_data, varargin)
%PLOT_HRV_NL_BETA Plots the MSE function.
%   ax: axes handle to plot to.
%   plot_data: struct returned from dfa.
%

%% Input
p = inputParser;
p.addRequired('ax', @(x) isgraphics(x, 'axes'));
p.addRequired('plot_data', @isstruct);
p.addParameter('clear', false, @islogical);
p.addParameter('tag', default_axes_tag(mfilename), @ischar);
p.addParameter('decimation_factor', 2, @isscalar);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
decimation_factor = p.Results.decimation_factor;

%% Plot
if clear
    cla(ax);
end

lw = 3.8;
ls = ':';

f_beta_plot = plot_data.f_axis(plot_data.beta_band_idx);
pxx_beta_plot = plot_data.pxx(plot_data.beta_band_idx);
f_axis_log = log10(f_beta_plot);

% Decimation
f_beta_plot = f_beta_plot(1:decimation_factor:end);
pxx_beta_plot = pxx_beta_plot(1:decimation_factor:end);

loglog(f_beta_plot, pxx_beta_plot, 'ko', 'Parent', ax, 'MarkerSize', 7);
hold(ax, 'on');
grid(ax, 'on');
axis(ax, 'tight');

% Plot the beta line
beta_line = plot_data.pxx_fit_beta(1) * f_axis_log + plot_data.pxx_fit_beta(2);
loglog(10.^f_axis_log, 10.^beta_line, 'Parent', ax, 'Color', 'magenta', 'LineStyle', ls, 'LineWidth', lw);

xlabel(ax, 'log(frequency [hz])');
ylabel(ax, 'log(PSD [s^2/Hz])');
legend(ax, 'PSD', ['\beta = ' num2str(plot_data.hrv_nl.beta)], 'Location', 'southwest');

%% Tag
ax.Tag = tag;

end

