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
p.addParameter('tag', default_axes_tag(mfilename), @ischar);
p.addParameter('linespec', '--ko', @ischar);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
linespec = p.Results.linespec;

%% Plot
if clear
    cla(ax);
end

% Plot MSE of the signal
plot(ax, plot_data.scale_axis, plot_data.mse_result, linespec, 'MarkerSize', 7);
grid(ax, 'on');
xlabel(ax, 'Scale factor'); ylabel(ax, 'Sample Entropy');
legend(ax, ['MSE, ', 'r=' num2str(plot_data.sampen_r), ' m=' num2str(plot_data.sampen_m)]);

%% Tag
ax.Tag = tag;

end

