function [] = plot_mse(ax, plot_data, varargin)
%PLOT_MSE Plots the MSE function.
%   ax: axes handle to plot to.
%   plot_data: struct returned from dfa.
%

%% Input
p = inputParser;
p.addRequired('ax', @(x) isgraphics(x, 'axes'));
p.addRequired('plot_data', @isstruct);
p.addParameter('clear', false, @islogical);
p.addParameter('tag', mhrv.plots.default_axes_tag(mfilename), @ischar);
p.addParameter('linespec', '--ko', @ischar);
p.addParameter('msz', 8, @isscalar);
p.addParameter('show_sampen', true, @islogical);
p.addParameter('legend_name', 'MSE', @ischar);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
linespec = p.Results.linespec;
msz = p.Results.msz;
show_sampen = p.Results.show_sampen;
legend_name = p.Results.legend_name;

%% Plot
if clear
    cla(ax);
end

curr_legend = legend(ax);
if curr_legend.isprop('String')
    legend_labels = curr_legend.String;
else
    legend_labels = {};
end

% Plot MSE of the signal
h1 = plot(ax, plot_data.scale_axis, plot_data.mse_result, linespec, 'MarkerSize', msz);
grid(ax, 'on'); hold(ax, 'on');
xlabel(ax, 'Scale'); ylabel(ax, 'Sample Entropy');
set(ax, 'XTick', plot_data.scale_axis(1):2:plot_data.scale_axis(end));
ylim(ax, [0, max(2, max(plot_data.mse_result))]); % SE values are usually between 0 and 2
legend_labels{end+1} = legend_name;

% If first scale factor is 1, also plot the SampEn value
if show_sampen && plot_data.scale_axis(1) == 1
    sampen = plot_data.mse_result(1);
    plot(ax, 1, sampen, 'r+', 'MarkerSize', 2 * msz);
    
    xl = xlim(ax);
    yl = ylim(ax);
    line([1, 1], [yl(1), sampen], 'Parent', ax, 'LineStyle', ':', 'Color', 'red', 'LineWidth', 1);
    line([xl(1), 1], [sampen, sampen], 'Parent', ax, 'LineStyle', ':', 'Color', 'red', 'LineWidth', 1);
    
    legend_labels{end+1} = sprintf('SampEn = %.3f', sampen);
end

legend(ax, legend_labels);

%% Tag
ax.Tag = tag;

end

