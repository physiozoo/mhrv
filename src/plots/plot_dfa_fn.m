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
p.addParameter('tag', default_axes_tag(mfilename), @ischar);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;

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
alpha1_line = fit_alpha1(1) * n_log(alpha1_idx) + fit_alpha1(2);
loglog(10.^n_log(alpha1_idx), 10.^alpha1_line, 'Parent', ax, 'Color', 'blue', 'LineStyle', ls, 'LineWidth', lw);

% Plot alpha2 line
alpha2_line = fit_alpha2(1) * n_log(alpha2_idx) + fit_alpha2(2);
loglog(10.^n_log(alpha2_idx), 10.^alpha2_line, 'Parent', ax, 'Color', 'red', 'LineStyle', ls, 'LineWidth', lw);

xlabel(ax, 'log(n)'); ylabel(ax, 'log(F(n))');
legend(ax, 'DFA', ['\alpha_1 = ' num2str(fit_alpha1(1))], ['\alpha_2 = ' num2str(fit_alpha2(1))], 'Location', 'northwest');
set(ax, 'XTick', [4, 8, 16, 32, 64, 128]);
uistack(h1, 'top');

%% Tag
ax.Tag = tag;

end

