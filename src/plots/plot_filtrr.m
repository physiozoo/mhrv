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

p.addParameter('plot_nn', true, @islogical);
p.addParameter('plot_outliers', true, @islogical);
p.addParameter('plot_avg', true, @islogical);
p.addParameter('plot_thresh', true, @islogical);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
yrange = p.Results.ylim;
msz = p.Results.msz;
lw_RR = p.Results.lw_RR;
lw_NN = p.Results.lw_NN;
plot_nn = p.Results.plot_nn;
plot_outliers = p.Results.plot_outliers;
plot_avg = p.Results.plot_avg;
plot_thresh = p.Results.plot_thresh;

%% Plot
if clear
    cla(ax);
end

hold(ax, 'on');
grid(ax, 'on');
xlabel(ax, 'time (s)');
ylabel(ax, 'RR Intervals (s)');
ylim(ax, yrange);

% Init legend data
legend_labels = {};
legend_handles = [];

% Plot original intervals
legend_handles(end+1) = plot(ax, plot_data.trr, plot_data.rri ,'b-', 'LineWidth', lw_RR);
legend_labels{end+1} = 'RR intervals';

% Plot filtered intervals
if plot_nn
    legend_handles(end+1) = plot(ax, plot_data.tnn, plot_data.nni, 'g-', 'LineWidth', lw_NN);
    legend_labels{end+1} = 'Filtered intervals';
end

if plot_outliers && ~isempty(plot_data.range_outliers)
    legend_handles(end+1) = plot(ax, plot_data.trr(plot_data.range_outliers), plot_data.rri(plot_data.range_outliers), 'm^', 'MarkerSize', msz+1);
    legend_labels{end+1} = 'Range outliers';
end

if plot_outliers && ~isempty(plot_data.lp_outliers)
    legend_handles(end+1) = plot(ax, plot_data.trr(plot_data.lp_outliers), plot_data.rri(plot_data.lp_outliers), 'ko', 'MarkerSize', msz-1);
    legend_labels{end+1} = 'Lowpass outliers';
end

if plot_outliers && ~isempty(plot_data.quotient_outliers)
    legend_handles(end+1) = plot(ax, plot_data.trr(plot_data.quotient_outliers), plot_data.rri(plot_data.quotient_outliers), 'rx', 'MarkerSize', msz);
    legend_labels{end+1} = 'Quotient outliers';
end

% Plot window average and thresholds
if ~isempty(plot_data.rri_lp)
    % Calculate threshold lines
    tresh_low   = plot_data.rri_lp.*(1.0 - plot_data.win_percent/100);
    thresh_high = plot_data.rri_lp.*(1.0 + plot_data.win_percent/100);
    
    if plot_avg
        legend_handles(end+1) = plot(ax, plot_data.trr, plot_data.rri_lp, 'k');
        legend_labels{end+1} = 'window average';
    end

    if plot_thresh
        h = plot(ax, plot_data.trr, tresh_low, 'k--', plot_data.trr, thresh_high, 'k--');
        legend_handles(end+1) = h(1);
        legend_labels{end+1} = 'window threshold';
    end
end

legend(ax, legend_handles, legend_labels);

%% Tag
ax.Tag = tag;

end

