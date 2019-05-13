function [] = plot_hrv_time_hist(ax, plot_data, varargin)
%PLOT_HRV_TIME_HIST Plots the hrv_time intervals histogram.
%   ax: axes handle to plot to.
%   plot_data: struct returned from hrv_time.
%

%% Input
p = inputParser;
p.addRequired('ax', @(x) isgraphics(x, 'axes'));
p.addRequired('plot_data', @isstruct);
p.addParameter('clear', false, @islogical);
p.addParameter('tag', mhrv.plots.default_axes_tag(mfilename), @ischar);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;

nni = plot_data.nni;
hrv_td = plot_data.hrv_td;

%% Plot
if clear
    cla(ax);
end

[~] = histogram(ax, nni, 'Normalization','probability');

xlabel(ax, 'NN Interval (ms)'); ylabel(ax, 'Probability');

line(ones(1,2)*hrv_td.AVNN, ylim(ax), 'Parent', ax, 'LineStyle', '-', 'Color', 'red', 'LineWidth', 2.5);
line(ones(1,2)*(hrv_td.AVNN + hrv_td.SDNN), ylim(ax), 'Parent', ax, 'LineStyle', ':', 'Color', 'red', 'LineWidth', 2);
line(ones(1,2)*(hrv_td.AVNN - hrv_td.SDNN), ylim(ax), 'Parent', ax, 'LineStyle', ':', 'Color', 'red', 'LineWidth', 2);

legend(ax, {'Interval Probability', sprintf('AVNN = %.3f', hrv_td.AVNN), sprintf('SDNN = %.3f', hrv_td.SDNN)});

%% Tag
ax.Tag = tag;

end

