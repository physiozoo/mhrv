function [] = plot_filtrr(ax, plot_data, varargin)
%PLOT_FILTRR Plots filtered RR intervals from filtrr.
%   ax: axes handle to plot to.
%   plot_data: struct returned from filtrr.
%

%% Input
p = inputParser;
p.addRequired('ax', @(x) isgraphics(x, 'axes'));
p.addRequired('plot_data', @isstruct);
p.addParameter('clear', false, @islogical);
p.addParameter('tag', default_axes_tag(mfilename), @ischar);
p.addParameter('ylim', 'auto');
p.addParameter('msz', 8, @isscalar);
p.addParameter('lw_RR', 2, @isscalar);
p.addParameter('lw_NN', 1, @isscalar);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
yrange = p.Results.ylim;
msz = p.Results.msz;
lw_RR = p.Results.lw_RR;
lw_NN = p.Results.lw_NN;

%% Plot
if clear
    cla(ax);
end

hold(ax, 'on');
grid(ax, 'on');
xlabel(ax, 'time [s]');
ylabel(ax, 'RR Intervals [s]');
ylim(ax, yrange);

% Plot original intervals
plot(ax, plot_data.trr, plot_data.rri ,'b-', 'LineWidth', lw_RR);
legend_labels = {'RR intervals'};

% Plot filtered intervals
plot(ax, plot_data.tnn, plot_data.nni, 'g-', 'LineWidth', lw_NN);
legend_labels{end+1} = 'Filtered intervals';

if (~isempty(plot_data.range_outliers))
    plot(ax, plot_data.trr(plot_data.range_outliers), plot_data.rri(plot_data.range_outliers),...
         'm^', 'MarkerSize', msz+1);

    legend_labels{end+1} = 'Range outliers';
end

if (~isempty(plot_data.lp_outliers))
    plot(ax, plot_data.trr(plot_data.lp_outliers), plot_data.rri(plot_data.lp_outliers),...
         'ko', 'MarkerSize', msz-1);

    legend_labels{end+1} = 'Lowpass outliers';
end

if (~isempty(plot_data.quotient_outliers))
    plot(ax, plot_data.trr(plot_data.quotient_outliers), plot_data.rri(plot_data.quotient_outliers),...
         'rx', 'MarkerSize', msz);

    legend_labels{end+1} = 'Quotient outliers';
end

% Plot window average and thresholds
if ~isempty(plot_data.rri_lp)
    % Calculate threshold lines
    tresh_low   = plot_data.rri_lp.*(1.0 - plot_data.win_percent/100);
    thresh_high = plot_data.rri_lp.*(1.0 + plot_data.win_percent/100);
    
    plot(ax, plot_data.trr, plot_data.rri_lp, 'k',...
         plot_data.trr, tresh_low, 'k--',...
         plot_data.trr, thresh_high, 'k--');

    legend_labels = [legend_labels, {'window average', 'window threshold'}];
end

legend(ax, legend_labels);

%% Tag
ax.Tag = tag;

end

