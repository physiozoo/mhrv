function [ mse_result, scale_axis ] = mse( sig, varargin )
%MSE Multi-scale entropy of a signal
%   Detailed explanation goes here

%% === Input
DEFAULT_MSE_MAX_SCALE = 20;
DEFAULT_SAMPEN_R = 0.2; % percent of std. dev.
DEFAULT_SAMPEN_M = 2;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('sig', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('mse_max_scale', DEFAULT_MSE_MAX_SCALE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_r', DEFAULT_SAMPEN_R, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_m', DEFAULT_SAMPEN_M, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(sig, varargin{:});
mse_max_scale = p.Results.mse_max_scale;
sampen_r = p.Results.sampen_r;
sampen_m = p.Results.sampen_m;
should_plot = p.Results.plot;

% Normalize input
N = length(sig);
sig_normalized = sig - mean(sig);
sig_normalized = sig_normalized / sqrt(var(sig_normalized));

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
    mse_result(scale) = sample_entropy(sig_coarse, sampen_m, sampen_r);
end

if (should_plot)
    % Plot MSE of the signal
    figure;
    plot(scale_axis, mse_result, '--ko', 'MarkerSize', 7); hold on;
    
    % Also plot the MSE of a shuffled version of the signal for comparison
    sig_shuffled = sig(randperm(N));
    [mse_shuffled, ~] = mse(sig_shuffled, 'mse_max_scale', mse_max_scale, 'sampen_r', sampen_r, 'sampen_m', sampen_m);
    plot(scale_axis, mse_shuffled, '--rx', 'MarkerSize', 7);

    grid on;
    xlabel('Scale factor'); ylabel('Sample Entropy');
    title(['MSE, ', 'r=' num2str(sampen_r), ' m=' num2str(sampen_m)]);
    legend('Original', 'Shuffled');
end
end
