function [ hrv_td, plot_data ] = hrv_time( nni, varargin )
%HRV_TIME Calculate time-domain HRV mertics from NN intervals
%   Input:
%       - nni: Vector of NN-interval lengths
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - pnn_thresh_ms - Optional. Threshold NN interval time difference in
%                             milliseconds (for the pNNx HRV measure).
%           - plot: true/false whether to generate a plot. Defaults to true if no output
%                   arguments were specified.
%   Output: Struct containing the following HRV metrics:
%       AVNN - Average NN interval length
%       SDNN - Standard deviation of NN interval lengths
%       RMSSD - Square root of mean summed squares of NN interval differences
%       pNNx - The percentage of NN intervals which differ by at least x [ms] (default 50)
%              from their preceding interval. The value of x in milliseconds can be set
%              with the optional parameter 'pnn_thresh_ms'.
%       SEM - Standard error of the mean NN interval length.

%% === Input
% Defaults
DEFAULT_PNN_THRESH_MS = rhrv_default('hrv_time.pnn_thresh_ms', 50); % millisec

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

%% Time Domain Metrics
hrv_td = struct;

hrv_td.AVNN = mean(nni);
hrv_td.SDNN = sqrt(var(nni));
hrv_td.RMSSD = sqrt(mean(diff(nni).^2));
hrv_td.pNNx = sum(abs(diff(nni)) > (pnn_thresh_ms / 1000))/(length(nni)-1);
hrv_td.SEM = (hrv_td.SDNN / sqrt(length(nni))) * 100;

%% Create plot data
plot_data.nni = nni;
plot_data.hrv_td = hrv_td;

%% Plot
if should_plot
    figure('Name', 'Time Domain HRV');
    plot_hrv_time_hist(gca, plot_data);
end

end

