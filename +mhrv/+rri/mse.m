function [ mse_result, scale_axis, plot_data ] = mse( sig, varargin )
%Calculates the Multiscale Entropy [2]_, MSE, of a signal, a measure of the
%signals complexity.  The algorithms calculates the Sample Entropy of the
%signal at various 'scales' from 1 to max_scale. At each scale, the signal is
%downsampled by averaging 'scale' samples and the Sample Entropy is calculated
%for the downsampled signal.
%
%:param sig: Signal to calculate MSE for.
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - mse_max_scale: Maximal scale to calculate up to. Default: 20.
%   - sampen_r: Value of 'r' parameter to use when calculating sample entropy
%     (max distance between two points that's considered a match). Default: 0.2.
%   - sampen_m: Value of 'm' parameter to use when calculating sample entropy
%     (length of templates to match). Default: 2.
%   - normalize_std: Whether or not to normalize the signal to std=1 before
%     calculating the MSE. This affects the meaning of r.
%   - plot: true/false whether to generate a plot. Defaults to true if no
%     output arguments were specified.
%
%:returns:
%
%   - mse_result: The sample entropy value at each scale.
%   - scale_axis: The corresponding scale values that were used.
%
%.. [2] Costa, M. D., Goldberger, A. L. and Peng, C.-K. (2005) ‘Multiscale
%   entropy analysis of biological signals’, Physical Review E - Statistical,
%   Nonlinear, and Soft Matter Physics, 71(2), pp. 1–18.

import mhrv.defaults.*;

%% Input
DEFAULT_MSE_MAX_SCALE = mhrv_get_default('mse.mse_max_scale', 'value');
DEFAULT_SAMPEN_R = mhrv_get_default('mse.sampen_r', 'value');
DEFAULT_SAMPEN_M = mhrv_get_default('mse.sampen_m', 'value');
DEFAULT_NORMALIZE_STD = mhrv_get_default('mse.normalize_std', 'value');

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('sig', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('mse_max_scale', DEFAULT_MSE_MAX_SCALE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_r', DEFAULT_SAMPEN_R, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_m', DEFAULT_SAMPEN_M, @(x) isnumeric(x) && isscalar(x));
p.addParameter('normalize_std', DEFAULT_NORMALIZE_STD, @(x) islogical(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(sig, varargin{:});
mse_max_scale = p.Results.mse_max_scale;
sampen_r = p.Results.sampen_r;
sampen_m = p.Results.sampen_m;
normalize_std = p.Results.normalize_std;
should_plot = p.Results.plot;

%% MSE Calculation
% Normalize input
N = length(sig);
sig_normalized = sig - mean(sig);
if normalize_std
    sig_normalized = sig_normalized / sqrt(var(sig_normalized));
end

% Preallocate result vector
mse_result = zeros(1, mse_max_scale);

scale_axis = 1:mse_max_scale;
for scale = scale_axis
    % Split the signal into windows of length 'scale'
    max_idx = floor(N/scale) * scale;
    sig_windows = reshape(sig_normalized(1:max_idx), scale, []);
    
    % Calculate the mean of each window to obtain the 'coarse-grained' signal
    sig_coarse = mean(sig_windows, 1);
    
    % Calculate sample entropy of the coarse-grained signal
    sampen = mhrv.rri.sample_entropy(sig_coarse, sampen_m, sampen_r);

    % An infinite sample entropy is possible, since
    % SampEn = -ln(A/B) where A is the number of template matches of length
    % m+1 and B is the number of template matches of length m. It's
    % possible that A will be zero or both will be zero (it's not possible
    % that only B will be zero). In the case of A=0, we'll get infinity.
    % Set it to NaN because:
    % 1. Consistent with the case of A=B=0.
    % 2. Easier to work with nans (e.g. to exclude them from calculations).
    % We don't do this in the SampEn function because there is a different
    % meaning to both this cases which will be hidden if we do it there.
    if isinf(sampen)
        sampen = NaN;
    end

    mse_result(scale) = sampen;
end

%% Plot
plot_data.name = ['MSE, ', 'r=' num2str(sampen_r), ' m=' num2str(sampen_m)];
plot_data.scale_axis = scale_axis;
plot_data.mse_result = mse_result;
plot_data.sampen_r = sampen_r;
plot_data.sampen_m = sampen_m;

if (should_plot)
    figure('Name', plot_data.name);
    plot_mse(gca, plot_data);
end
end
