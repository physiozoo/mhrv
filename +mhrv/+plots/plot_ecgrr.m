function [] = plot_ecgrr(ax, plot_data, varargin)
%PLOT_ECGRR Plots filtered RR intervals from ecgrr.
%   ax: axes handle to plot to.
%   plot_data: struct returned from ecgrr.
%

%% Input
p = inputParser;
p.addRequired('ax', @(x) isgraphics(x, 'axes'));
p.addRequired('plot_data', @isstruct);
p.addParameter('clear', false, @islogical);
p.addParameter('tag', mhrv.plots.default_axes_tag(mfilename), @ischar);
p.addParameter('msz', 8, @isscalar);

p.parse(ax, plot_data, varargin{:});
clear = p.Results.clear;
tag = p.Results.tag;
msz = p.Results.msz;

%% Plot
if clear
    cla(ax);
end

hold(ax, 'on');
grid(ax, 'on');
xlabel(ax, 'time (s)');
ylabel(ax, 'ECG (mV)');

plot(ax, plot_data.tm, plot_data.sig);
plot(ax, plot_data.tm(plot_data.qrs), plot_data.sig(plot_data.qrs,1), 'rx', 'MarkerSize', msz);

legend(ax, 'ECG signal', 'R-peaks');

%% Tag
ax.Tag = tag;

end

