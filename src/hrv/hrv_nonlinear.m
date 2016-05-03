function [ hrv_nl ] = hrv_nonlinear( nni, tm_nni, varargin )
%HRV_NONLINEAR Calcualte non-linear HRV metrics
%   Detailed explanation goes here

%% === Input
DEFAULT_ALPHA1_RANGE = [4, 15];
DEFAULT_ALPHA2_RANGE = [16, 128];
DEFAULT_NMIN = 3;
DEFAULT_NMAX = 150;
DEFAULT_BETA_BAND = [0.003, 0.04]; % hz
DEFAULT_MSE_MAX_SCALE = 20;
DEFAULT_SAMPEN_R = 0.15; % percent of std. dev.
DEFAULT_SAMPEN_M = 2;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('nni', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('tm_nni', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('alpha1_range',  DEFAULT_ALPHA1_RANGE, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('alpha2_range',  DEFAULT_ALPHA2_RANGE, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('n_min',  DEFAULT_NMIN, @(x) isnumeric(x) && isscalar(x));
p.addParameter('n_max',  DEFAULT_NMAX, @(x) isnumeric(x) && isscalar(x));
p.addParameter('beta_band',  DEFAULT_BETA_BAND, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('mse_max_scale', DEFAULT_MSE_MAX_SCALE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_r', DEFAULT_SAMPEN_R, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_m', DEFAULT_SAMPEN_M, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(nni, tm_nni, varargin{:});
alpha1_range = p.Results.alpha1_range;
alpha2_range = p.Results.alpha2_range;
n_min = p.Results.n_min;
n_max = p.Results.n_max;
beta_band = p.Results.beta_band;
mse_max_scale = p.Results.mse_max_scale;
sampen_r = p.Results.sampen_r;
sampen_m = p.Results.sampen_m;
should_plot = p.Results.plot;

%% === DFA

% Integrate the NN intervals without mean
nni_int = cumsum(nni - mean(nni));

N = length(nni_int);
DFA_Fn = ones(n_max, 1) * NaN;

for n = n_min:n_max
    % Calculate the number of windows we need for the current n
    num_win = floor(N/n);

    % Break the signal into num_win windows of n samples each
    nni_windows = reshape(nni_int(1:n*num_win), n, num_win);
    tm_windows  = reshape(tm_nni(1:n*num_win), n, num_win);
    nni_regressed = zeros(size(nni_windows));

    % Perform linear regression in each window
    for ii = 1:num_win
        y = nni_windows(:, ii);
        x = [ones(n, 1), tm_windows(:, ii)];
        b = x\y;
        yn = x * b;
        nni_regressed(:, ii) = yn;
    end

    % Calculate F(n), the value of the DFA for the current n
    DFA_Fn(n) = sqrt ( 1/N * sum((nni_windows(:) - nni_regressed(:)).^2) );
end

% Find the indices of all the DFA values we calculated
DFA_Fn = DFA_Fn(n_min:n_max);
DFA_n  = (n_min:n_max)';

%% === Nonlinear metrics (short and long-term scaling exponents, alpha1 & alpha2)

alpha1_idx = find(DFA_n >= alpha1_range(1) & DFA_n <= alpha1_range(2));
alpha2_idx = find(DFA_n >= alpha2_range(1) & DFA_n <= alpha2_range(2));

DFA_Fn_log = log10(DFA_Fn);
DFA_n_log = log10(DFA_n);

DFA_fit_alpha1 = polyfit(DFA_n_log(alpha1_idx), DFA_Fn_log(alpha1_idx), 1);
DFA_fit_alpha2 = polyfit(DFA_n_log(alpha2_idx), DFA_Fn_log(alpha2_idx), 1);

hrv_nl = struct;
hrv_nl.alpha1 = DFA_fit_alpha1(1);
hrv_nl.alpha2 = DFA_fit_alpha2(1);

%% === Nonlinear metrics (spectral power-law exponent, beta)

% Calculate spectrum
[ ~, pxx, f_axis ] = hrv_freq(nni, tm_nni, 'method', 'lomb');

% Take the log of the spectrum in the beta frequency band
beta_band_idx = find(f_axis >= beta_band(1) & f_axis <= beta_band(2));
pxx_log = log10(pxx(beta_band_idx));
f_axis_log = log10(f_axis(beta_band_idx));

% Fit a line and get the slope
pxx_fit_beta = polyfit(f_axis_log, pxx_log, 1);
hrv_nl.beta = pxx_fit_beta(1);

%% === Nonlinear metrics (Multiscale sample entropy)

[ mse_values, scale_axis ] = mse(nni, 'mse_max_scale', mse_max_scale, 'sampen_m', sampen_m, 'sampen_r',sampen_r);

% TODO: Decide what metric to calculate from the mse values.

%% === Display output if requested
if (should_plot)
    set(0,'DefaultAxesFontSize',14);
    lw = 3.8; ls = ':';
    figure;

    % Plot the DFA data
    subplot(3, 1, 1);
    loglog(DFA_n, DFA_Fn, 'ko', 'MarkerSize', 7);
    hold on; grid on;

    % Plot alpha1 line
    alpha1_line = DFA_fit_alpha1(1) * DFA_n_log(alpha1_idx) + DFA_fit_alpha1(2);
    loglog(10.^DFA_n_log(alpha1_idx), 10.^alpha1_line, 'Color', 'blue', 'LineStyle', ls, 'LineWidth', lw);

    % Plot alpha2 line
    alpha2_line = DFA_fit_alpha2(1) * DFA_n_log(alpha2_idx) + DFA_fit_alpha2(2);
    loglog(10.^DFA_n_log(alpha2_idx), 10.^alpha2_line, 'Color', 'red', 'LineStyle', ls, 'LineWidth', lw);

    xlabel('Block size (n)'); ylabel('log_{10}(F(n))');
    legend('DFA', ['\alpha_1 = ' num2str(hrv_nl.alpha1)], ['\alpha_2 = ' num2str(hrv_nl.alpha2)]);
    set(gca, 'XTick', [4, 8, 16, 32, 64, 128]);

    % Plot the spectrum (only plot every x samples)
    f_beta_plot = f_axis(beta_band_idx);
    pxx_beta_plot = pxx(beta_band_idx);
    decimation_factor = 10;
    subplot(3, 1, 2);
    loglog(f_beta_plot(1:decimation_factor:end), pxx_beta_plot(1:decimation_factor:end), 'ko', 'MarkerSize', 7);
    hold on; grid on;

    % Plot the beta line
    beta_line = pxx_fit_beta(1) * f_axis_log + pxx_fit_beta(2);
    loglog(10.^f_axis_log, 10.^beta_line, 'Color', 'magenta', 'LineStyle', ls, 'LineWidth', lw);
    xlabel('log(frequency [hz])'); ylabel('log(PSD [s^2/Hz])');
    legend('PSD', ['\beta = ' num2str(hrv_nl.beta)]);

    % Plot MSE
    subplot(3, 1, 3);
    plot(scale_axis, mse_values, '--ko', 'MarkerSize', 7); grid on;
    xlabel('Scale factor'); ylabel('Sample Entropy');
    legend(['MSE, ', 'r=' num2str(sampen_r), ' m=' num2str(sampen_m)]);
end
