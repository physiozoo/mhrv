function [] = plot_hrv_freq_beta(ax, plot_data, varargin)
%PLOT_HRV_NL_BETA Plots the slope of the log-log spectrum in the VLF range.
%   ax: axes handle to plot to.
%   plot_data: struct returned from hrv_freq.
%

%% Input
SUPPORTED_METHODS = {'Lomb', 'AR', 'Welch', 'FFT'};

p = inputParser;
p.addRequired('ax', @(x) isgraphics(x, 'axes'));
p.addRequired('plot_data', @isstruct);
p.addParameter('clear', false, @islogical);
p.addParameter('methods', SUPPORTED_METHODS, @(x) cellfun(@(m) any(cellfun(@(ms) strcmp(m,ms), SUPPORTED_METHODS)), x));
p.addParameter('tag', mhrv.plots.default_axes_tag(mfilename), @ischar);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
methods = p.Results.methods;

%% Plot
if clear
    cla(ax);
end

colors = lines(length(SUPPORTED_METHODS));

% Check for pre-existing plots frequency plots on this axes
legend_handles = findall(ax,'Tag','beta');
legend_entries = {};
if ~isempty(legend_handles)
    lgd = legend(ax);
    legend_entries = lgd.String;
    colors = colors((length(legend_handles)+1):end,:);
end

hold(ax, 'on');
f_axis_beta = plot_data.f_axis(plot_data.beta_idx);
for ii = 1:length(methods)
    pxx = plot_data.(['pxx_' lower(methods{ii})]);
    pxx = pxx * 1e6; % convert to ms^2/Hz

    % Skip this power method if it wasn't calculated or if it wasn't requested for plotting
    if isempty(pxx) || ~any(cellfun(@(m) strcmp(methods{ii}, m), methods))
        continue;
    end

    % Plot the spectrum in the beta band
    pxx_beta = pxx(plot_data.beta_idx);
    plot(ax, f_axis_beta, pxx_beta, 'Color', colors(ii,:), 'LineWidth', 1.5, 'Tag','beta');

    % Fit a line and get the slope
    pxx_beta_log = log10(pxx_beta);
    f_axis_beta_log = log10(f_axis_beta);
    pxx_fit_beta = polyfit(f_axis_beta_log, pxx_beta_log, 1);

    % Plot the fitted line
    beta_line = pxx_fit_beta(1) * f_axis_beta_log + pxx_fit_beta(2);
    hl = plot(ax, 10.^f_axis_beta_log, 10.^beta_line, 'Color',  colors(ii,:), 'LineStyle', ':', 'LineWidth', 3.8);

    legend_handles(end+1) = hl;
    legend_entries{end+1} = sprintf('\\beta_{%s}=%.2f', upper(methods{ii}), pxx_fit_beta(1));
end

% Remove legend entries for unused methods
skipped_idx = find(legend_handles == 0);
legend_handles(skipped_idx) = [];
legend_entries(skipped_idx) = [];

% Set log-log plot
set(ax, 'XScale', 'log', 'YScale', 'log');
grid(ax, 'on');
axis(ax, 'tight');

xlabel(ax, 'log(frequency (hz))');
ylabel(ax, 'log(PSD [ms^2/Hz])');

legend(legend_handles, legend_entries, 'Location', 'southwest');

%% Tag
ax.Tag = tag;

end
