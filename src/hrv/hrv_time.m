function [ hrv_td ] = hrv_time( nni, varargin )
%HRV_TIME Calculate time-domain HRV mertics from NN intervals
%   Input:
%       nni - Vector of NN-interval lengths
%       pnn_thresh_ms - Optional. Threshold NN interval time difference in
%                       milliseconds (for the pNNx HRV measure).
%   Output: Struct containing the following HRV metrics:
%       AVNN - Average NN interval length
%       SDNN - Standard deviation of NN interval lengths
%       RMSSD - Square root of mean summed squares of NN interval differences
%       pNNx - The percentage of NN intervals which differ by at least x [ms] (default 50)
%              from their preceding interval. The value of x in milliseconds can be set
%              with the optional parameter 'pnn_thresh_ms'.

%% === Input
% Defaults
DEFAULT_PNN_THRESH_MS = 50; % millisec

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('nni', @isvector);
p.addParameter('pnn_thresh_ms', DEFAULT_PNN_THRESH_MS, @isscalar);

% Get input
p.parse(nni, varargin{:});
pnn_thresh_ms = p.Results.pnn_thresh_ms;

%% === Time Domain Metrics
hrv_td = struct;

hrv_td.AVNN = mean(nni);
hrv_td.SDNN = sqrt(var(nni));
hrv_td.RMSSD = sqrt(mean(diff(nni).^2));
hrv_td.pNNx = sum(abs(diff(nni)) > (pnn_thresh_ms / 1000))/(length(nni)-1);

end

