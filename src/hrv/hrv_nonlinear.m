function [ hrv_nl, plot_data ] = hrv_nonlinear( nni, varargin )
%HRV_NONLINEAR Calcualte non-linear HRV metrics.
%   Inputs:
%       - nni: RR/NN intervals, in seconds.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - beta_band: A 2-element vector specifying the frequency range (in Hz) to use for
%             calculating the beta parameter. Default: [0.003, 0.04].
%
%   Output:
%       - hrv_nl: Table containing the following HRV metrics:
%           - SD1: Poincare plot SD1 descriptor (std. dev. of intervals along the line perpendicular
%             to the line of identity).
%           - SD2: Poincare plot SD2 descriptor (std. dev. of intervals along the line of identity).
%           - alpha1: Log-log slope of DFA in the low-scale region.
%           - alpha2: Log-log slope of DFA in the high-scale region.
%           - beta: Log-log slope of frequency in VLF band.
%           - SampEn: The sample entropy.
%

%% Input
DEFAULT_MSE_MAX_SCALE = rhrv_get_default('mse.mse_max_scale', 'value');
DEFAULT_MSE_METRICS = rhrv_get_default('mse.mse_metrics', 'value');
DEFAULT_SAMPEN_R = rhrv_get_default('mse.sampen_r', 'value');
DEFAULT_SAMPEN_M = rhrv_get_default('mse.sampen_m', 'value');

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('nni', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('mse_max_scale', DEFAULT_MSE_MAX_SCALE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('mse_metrics', DEFAULT_MSE_METRICS, @(x) islogical(x) && isscalar(x));
p.addParameter('sampen_r', DEFAULT_SAMPEN_R, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_m', DEFAULT_SAMPEN_M, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(nni, varargin{:});
mse_max_scale = p.Results.mse_max_scale;
mse_metrics = p.Results.mse_metrics;
sampen_r = p.Results.sampen_r;
sampen_m = p.Results.sampen_m;
should_plot = p.Results.plot;

% Create output table
hrv_nl = table;
hrv_nl.Properties.Description = 'Nonlinear HRV Metrics';

%% Preprocess

% Calculate zero-based interval time axis
nni = nni(:);
tnn = [0; cumsum(nni(1:end-1))];

%% Poincare plot

[sd1, sd2, poincare_plot_data] = poincare(nni, 'plot', false);
hrv_nl.SD1 = sd1 * 1000;
hrv_nl.Properties.VariableUnits{'SD1'} = 'ms';
hrv_nl.Properties.VariableDescriptions{'SD1'} = 'NN interval standard deviation along the perpendicular';

hrv_nl.SD2 = sd2 * 1000;
hrv_nl.Properties.VariableUnits{'SD2'} = 'ms';
hrv_nl.Properties.VariableDescriptions{'SD2'} = 'NN interval standard deviation along the line-of-identity';

%% DFA-based Nonlinear metrics (short and long-term scaling exponents, alpha1 & alpha2)

% Calcualte DFA
[~, ~, alpha1, alpha2, dfa_plot_data] = dfa(tnn, nni);

% Save the scaling exponents
hrv_nl.alpha1 = alpha1;
hrv_nl.Properties.VariableUnits{'alpha1'} = 'n.u.';
hrv_nl.Properties.VariableDescriptions{'alpha1'} = 'DFA low-scale slope';

hrv_nl.alpha2 = alpha2;
hrv_nl.Properties.VariableUnits{'alpha2'} = 'n.u.';
hrv_nl.Properties.VariableDescriptions{'alpha2'} = 'DFA high-scale slope';

%% Multiscale sample entropy

% Calculate the MSE graph
[ mse_values, scale_axis, mse_plot_data ] = mse(nni, 'mse_max_scale', mse_max_scale, 'sampen_m', sampen_m, 'sampen_r',sampen_r);

% Save the first MSE value (this is the sample entropy).
if ~isempty(mse_values)
    hrv_nl.SampEn = mse_values(1);
    hrv_nl.Properties.VariableUnits{'SampEn'} = 'n.u.';
    hrv_nl.Properties.VariableDescriptions{'SampEn'} = 'Sample entropy';
end

if mse_metrics
    for ii = 1:length(mse_values)
        curr_metric_name = ['MSE' num2str(scale_axis(ii))];
        hrv_nl{:, curr_metric_name} = mse_values(ii);
        hrv_nl.Properties.VariableUnits{curr_metric_name} = 'n.u.';
        hrv_nl.Properties.VariableDescriptions{curr_metric_name} = sprintf('MSE value at scale %d', scale_axis(ii));
    end
end

%% Create plot data
plot_data.name = 'Nonlinear HRV';
plot_data.poincare = poincare_plot_data;
plot_data.dfa = dfa_plot_data;
plot_data.mse = mse_plot_data;

%% Display output if requested
if (should_plot) 
    figure('Name', plot_data.name);
    
    hsub1 = subplot(2, 1, 1);
    plot_dfa_fn(hsub1, plot_data.dfa);

    hsub3 = subplot(2, 1, 2);
    plot_mse(hsub3, plot_data.mse);
end
