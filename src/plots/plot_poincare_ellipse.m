function [] = plot_poincare_ellipse(ax, plot_data, varargin)
%PLOT_POINCARE_ELLIPSE Plots a poincare plot and an ellipse fit.
%   ax: axes handle to plot to.
%   plot_data: struct returned from poincare.
%

%% Input
p = inputParser;
p.addRequired('ax', @(x) isgraphics(x, 'axes'));
p.addRequired('plot_data', @isstruct);
p.addParameter('clear', false, @islogical);
p.addParameter('tag', default_axes_tag(mfilename), @ischar);
p.addParameter('msz', 4, @isscalar);
p.addParameter('lw_ellipse', 1.5, @isscalar);
p.addParameter('lw_sdline', 3, @isscalar);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
msz = p.Results.msz;
lw_ellipse = p.Results.lw_ellipse;
lw_sdline = p.Results.lw_sdline;

%% Plot
if clear
    cla(ax);
end

hold(ax, 'on');
axis(ax, 'equal', 'tight');
grid(ax, 'on');
xlabel(ax, 'RR(n) [sec]');
ylabel(ax, 'RR(n+1) [sec]');

plot(ax, plot_data.x_orig, plot_data.y_orig, 'b+', 'MarkerSize', msz);
plot(ax, plot_data.ellipse_old(1,:), plot_data.ellipse_old(2,:),'k--', 'LineWidth', lw_ellipse);

h_sd1 = plot(ax, plot_data.sd1_line_old(1,:), plot_data.sd1_line_old(2,:), 'r-', 'LineWidth', lw_sdline);
h_sd2 = plot(ax, plot_data.sd2_line_old(1,:), plot_data.sd2_line_old(2,:), 'g-', 'LineWidth', lw_sdline);

legend([h_sd1,h_sd2], {sprintf('SD1=%.4f', plot_data.sd1), sprintf('SD2=%.4f', plot_data.sd2)});

%% Tag
ax.Tag = tag;

end

