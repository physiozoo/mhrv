function [ hrv_td, plot_data ] = hrv_time( nni, varargin )
%Calculates time-domain HRV mertics from NN intervals.
%
%:param nni: Vector of NN-interval dirations (in seconds)
%
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - pnn_thresh_ms: Optional. Threshold NN interval time difference in
%     milliseconds (for the pNNx HRV measure).
%   - plot: true/false whether to generate a plot. Defaults to true if no
%     output arguments were specified.
%
%:returns: Table containing the following HRV metrics:
%
%       - AVNN: Average NN interval duration.
%       - SDNN: Standard deviation of NN interval durations.
%       - RMSSD: Square root of mean summed squares of NN interval differences.
%       - pNNx: The percentage of NN intervals which differ by at least x (ms)
%         (default 50) from their preceding interval. The value of x in
%         milliseconds can be set with the optional parameter 'pnn_thresh_ms'.
%       - SEM: Standard error of the mean NN interval length.
%

import mhrv.defaults.*;

%% === Input
% Defaults
DEFAULT_PNN_THRESH_MS = mhrv_get_default('hrv_time.pnn_thresh_ms', 'value');

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('nni', @(x) isempty(x) || isvector(x));
p.addParameter('pnn_thresh_ms', DEFAULT_PNN_THRESH_MS, @isscalar);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(nni, varargin{:});
pnn_thresh_ms = p.Results.pnn_thresh_ms;
should_plot = p.Results.plot;

% Convert to milliseconds
nni = nni * 1000;

%% Time Domain Metrics
hrv_td = table;
hrv_td.Properties.Description = 'Time domain HRV metrics';

hrv_td.AVNN = mean(nni);
hrv_td.Properties.VariableUnits{'AVNN'} = 'ms';
hrv_td.Properties.VariableDescriptions{'AVNN'} = 'Average NN interval duration';

hrv_td.SDNN = sqrt(var(nni));
hrv_td.Properties.VariableUnits{'SDNN'} = 'ms';
hrv_td.Properties.VariableDescriptions{'SDNN'} = 'Standard deviation of NN interval duration';

hrv_td.RMSSD = sqrt(mean(diff(nni).^2));
hrv_td.Properties.VariableUnits{'RMSSD'} = 'ms';
hrv_td.Properties.VariableDescriptions{'RMSSD'} = 'The square root of the mean of the sum of the squares of differences between adjacent NN intervals';

hrv_td.pNNx = 100 * sum(abs(diff(nni)) > pnn_thresh_ms) / (length(nni)-1);
hrv_td.Properties.VariableUnits{'pNNx'} = '%';
hrv_td.Properties.VariableDescriptions{'pNNx'} = sprintf('Percent of NN interval differences greater than %.1fmilliseconds', pnn_thresh_ms);
hrv_td.Properties.VariableNames{'pNNx'} = ['pNN' num2str(floor(pnn_thresh_ms))]; % change name to e.g. pNN50

hrv_td.SEM = hrv_td.SDNN / sqrt(length(nni));
hrv_td.Properties.VariableUnits{'SEM'} = 'ms';
hrv_td.Properties.VariableDescriptions{'SEM'} = 'Standard error of the mean NN interval';

%% Plot
plot_data.name = 'Intervals Histogram';
plot_data.nni = nni;
plot_data.hrv_td = hrv_td;

if should_plot
    figure('Name', plot_data.name);
    plot_hrv_time_hist(gca, plot_data);
end

end

