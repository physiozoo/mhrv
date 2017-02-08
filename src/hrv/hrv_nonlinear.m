function [ hrv_nl ] = hrv_nonlinear( nni, tm_nni, varargin )
%HRV_NONLINEAR Calcualte non-linear HRV metrics
%   Detailed explanation goes here

%% === Input
DEFAULT_ALPHA1_RANGE = [4, 15];
DEFAULT_ALPHA2_RANGE = [16, 128];
DEFAULT_DFA_NMIN = 4;
DEFAULT_DFA_NMAX = 150;
DEFAULT_BETA_BAND = [0.003, 0.04]; % hz
DEFAULT_MSE_MAX_SCALE = 20;
DEFAULT_MSE_FIT_SCALE = 7;
DEFAULT_SAMPEN_R = 0.15; % percent of std. dev.
DEFAULT_SAMPEN_M = 2;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('nni', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('tm_nni', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('alpha1_range',  DEFAULT_ALPHA1_RANGE, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('alpha2_range',  DEFAULT_ALPHA2_RANGE, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('dfa_n_min',  DEFAULT_DFA_NMIN, @(x) isnumeric(x) && isscalar(x));
p.addParameter('dfa_n_max',  DEFAULT_DFA_NMAX, @(x) isnumeric(x) && isscalar(x));
p.addParameter('beta_band',  DEFAULT_BETA_BAND, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('mse_max_scale', DEFAULT_MSE_MAX_SCALE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('mse_fit_scale', DEFAULT_MSE_FIT_SCALE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_r', DEFAULT_SAMPEN_R, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_m', DEFAULT_SAMPEN_M, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(nni, tm_nni, varargin{:});
alpha1_range = p.Results.alpha1_range;
alpha2_range = p.Results.alpha2_range;
dfa_n_min = p.Results.dfa_n_min;
dfa_n_max = p.Results.dfa_n_max;
beta_band = p.Results.beta_band;
mse_max_scale = p.Results.mse_max_scale;
mse_fit_scale = p.Results.mse_fit_scale;
sampen_r = p.Results.sampen_r;
sampen_m = p.Results.sampen_m;
should_plot = p.Results.plot;

% Create output struct
hrv_nl = struct;

%% Poincare plot

[sd1, sd2, ~] = poincare(nni, 'plot', should_plot);
hrv_nl.SD1 = sd1;
hrv_nl.SD2 = sd2;

%% === DFA-based Nonlinear metrics (short and long-term scaling exponents, alpha1 & alpha2)

% Calcualte DFA
[DFA_n, DFA_Fn] = dfa(tm_nni, nni, 'n_min', dfa_n_min, 'n_max', dfa_n_max, 'n_incr', 2);

% Find DFA values in each of the alpha ranges
alpha1_idx = find(DFA_n >= alpha1_range(1) & DFA_n <= alpha1_range(2));
alpha2_idx = find(DFA_n >= alpha2_range(1) & DFA_n <= alpha2_range(2));

% Fit a line to the log-log DFA in each alpha range
DFA_Fn_log = log10(DFA_Fn);
DFA_n_log = log10(DFA_n);
DFA_fit_alpha1 = polyfit(DFA_n_log(alpha1_idx), DFA_Fn_log(alpha1_idx), 1);
DFA_fit_alpha2 = polyfit(DFA_n_log(alpha2_idx), DFA_Fn_log(alpha2_idx), 1);

% Save the slopes of the lines
hrv_nl.alpha1 = DFA_fit_alpha1(1);
hrv_nl.alpha2 = DFA_fit_alpha2(1);

%% === Beta: Spectral power-law exponent

% Calculate spectrum
[ ~, pxx, f_axis ] = hrv_freq(nni, tm_nni, 'method', 'lomb');

% Take the log of the spectrum in the beta frequency band
beta_band_idx = find(f_axis >= beta_band(1) & f_axis <= beta_band(2));
pxx_log = log10(pxx(beta_band_idx));
f_axis_log = log10(f_axis(beta_band_idx));

% Fit a line and get the slope
pxx_fit_beta = polyfit(f_axis_log, pxx_log, 1);
hrv_nl.beta = pxx_fit_beta(1);

%% === Multiscale sample entropy

% Calculate the MSE graph
[ mse_values, scale_axis ] = mse(nni, 'mse_max_scale', mse_max_scale, 'sampen_m', sampen_m, 'sampen_r',sampen_r);

% Fit a straight line to the tail of the MSE graph
fit_idx = mse_fit_scale:length(scale_axis);
mse_fit = polyfit(scale_axis(fit_idx), mse_values(fit_idx), 1);

% Calculate metrics: The slope and intercept of the linefit to the MSE graph
hrv_nl.mse_a = mse_fit(1);
hrv_nl.mse_b = mse_fit(2);

%% === Display output if requested
if (should_plot)
    lw = 3.8; ls = ':';
    figure;

    % Plot the DFA data
    subplot(3, 1, 1);
    loglog(DFA_n, DFA_Fn, 'ko', 'MarkerSize', 7);
    hold on; grid on; axis tight;

    % Plot alpha1 line
    alpha1_line = DFA_fit_alpha1(1) * DFA_n_log(alpha1_idx) + DFA_fit_alpha1(2);
    loglog(10.^DFA_n_log(alpha1_idx), 10.^alpha1_line, 'Color', 'blue', 'LineStyle', ls, 'LineWidth', lw);

    % Plot alpha2 line
    alpha2_line = DFA_fit_alpha2(1) * DFA_n_log(alpha2_idx) + DFA_fit_alpha2(2);
    loglog(10.^DFA_n_log(alpha2_idx), 10.^alpha2_line, 'Color', 'red', 'LineStyle', ls, 'LineWidth', lw);

    xlabel('Block size (n)'); ylabel('log_{10}(F(n))');
    legend('DFA', ['\alpha_1 = ' num2str(hrv_nl.alpha1)], ['\alpha_2 = ' num2str(hrv_nl.alpha2)], 'Location', 'northwest');
    set(gca, 'XTick', [4, 8, 16, 32, 64, 128]);

    % Plot the spectrum (only plot every x samples)
    f_beta_plot = f_axis(beta_band_idx);
    pxx_beta_plot = pxx(beta_band_idx);
    decimation_factor = 10;
    subplot(3, 1, 2);
    loglog(f_beta_plot(1:decimation_factor:end), pxx_beta_plot(1:decimation_factor:end), 'ko', 'MarkerSize', 7);
    hold on; grid on;  axis tight;

    % Plot the beta line
    beta_line = pxx_fit_beta(1) * f_axis_log + pxx_fit_beta(2);
    loglog(10.^f_axis_log, 10.^beta_line, 'Color', 'magenta', 'LineStyle', ls, 'LineWidth', lw);
    xlabel('log(frequency [hz])'); ylabel('log(PSD [s^2/Hz])');
    legend('PSD', ['\beta = ' num2str(hrv_nl.beta)], 'Location', 'southwest');

    % Plot MSE & linefit
    subplot(3, 1, 3);
    plot(scale_axis, mse_values, '--ko', 'MarkerSize', 7); hold on; grid on;
    plot(scale_axis(fit_idx), scale_axis(fit_idx).*mse_fit(1) + mse_fit(2), 'Color', 'green', 'LineStyle', ls, 'LineWidth', lw);
    xlabel('Scale factor'); ylabel('Sample Entropy');
    legend(['MSE, ', 'r=' num2str(sampen_r), ' m=' num2str(sampen_m)], ['Fit, slope=' num2str(mse_fit(1))]);
end
