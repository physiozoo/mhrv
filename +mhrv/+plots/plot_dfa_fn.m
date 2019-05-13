function [] = plot_dfa_fn(ax, plot_data, varargin)
%PLOT_DFA_FN Plots the DFA F(n) function.
%   ax: axes handle to plot to.
%   plot_data: struct returned from dfa.
%

%% Input
p = inputParser;
p.addRequired('ax', @(x) isgraphics(x, 'axes'));
p.addRequired('plot_data', @isstruct);
p.addParameter('clear', false, @islogical);
p.addParameter('tag', mhrv.plots.default_axes_tag(mfilename), @ischar);
p.addParameter('detailed_legend', true);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
detailed_legend = p.Results.detailed_legend;

n             = plot_data.n;
fn            = plot_data.fn;
alpha1_idx    = plot_data.alpha1_idx;
alpha2_idx    = plot_data.alpha2_idx;
fit_alpha1    = plot_data.fit_alpha1;
fit_alpha2    = plot_data.fit_alpha2;

%% Plot
if clear
    cla(ax);
end

n_log = log10(n);

lw = 3.8; ls = ':';

h1 = loglog(n, fn, 'ko', 'Parent', ax, 'MarkerSize', 7);
hold(ax, 'on');
grid(ax, 'on');
axis(ax, 'tight');

% Plot alpha1 line
alpha1_line = 10.^(fit_alpha1(1) * n_log(alpha1_idx) + fit_alpha1(2));
loglog(n(alpha1_idx), alpha1_line, 'Parent', ax, 'Color', 'blue', 'LineStyle', ls, 'LineWidth', lw);

% Plot alpha2 line
alpha2_line = 10.^(fit_alpha2(1) * n_log(alpha2_idx) + fit_alpha2(2));
loglog(n(alpha2_idx), alpha2_line, 'Parent', ax, 'Color', 'red', 'LineStyle', ls, 'LineWidth', lw);

% Calculate fit R-square, to include in legend
if (detailed_legend)
    C1 = corrcoef(fn(alpha1_idx), alpha1_line);
    R2_1 = C1(1,2)^2;
    C2 = corrcoef(fn(alpha2_idx), alpha2_line);
    R2_2 = C2(1,2)^2;

    alpha1_legend = sprintf('\\alpha_1=%.3f (R^2=%.2f)', fit_alpha1(1), R2_1);
    alpha2_legend = sprintf('\\alpha_2=%.3f (R^2=%.2f)', fit_alpha2(1), R2_2);
else
    alpha1_legend = sprintf('\alpha_1=%.3f', fit_alpha1(1));
    alpha2_legend = sprintf('\alpha_2=%.3f', fit_alpha2(1));
end

xlabel(ax, 'log_2(n)'); ylabel(ax, 'F(n)');
set(ax, 'XTick', 2.^(1:15)); % Set ticks at powers of two

legend(ax, 'DFA', alpha1_legend, alpha2_legend, 'Location', 'northwest');
uistack(h1, 'top');

%% Tag
ax.Tag = tag;

end

