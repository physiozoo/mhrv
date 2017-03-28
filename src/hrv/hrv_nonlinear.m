function [ hrv_nl ] = hrv_nonlinear( nni, tm_nni, varargin )
%HRV_NONLINEAR Calcualte non-linear HRV metrics
%   Detailed explanation goes here

%% === Input
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
p.addParameter('beta_band',  DEFAULT_BETA_BAND, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('mse_max_scale', DEFAULT_MSE_MAX_SCALE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('mse_fit_scale', DEFAULT_MSE_FIT_SCALE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_r', DEFAULT_SAMPEN_R, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_m', DEFAULT_SAMPEN_M, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(nni, tm_nni, varargin{:});
beta_band = p.Results.beta_band;
mse_max_scale = p.Results.mse_max_scale;
mse_fit_scale = p.Results.mse_fit_scale;
sampen_r = p.Results.sampen_r;
sampen_m = p.Results.sampen_m;
should_plot = p.Results.plot;

% Create output struct
hrv_nl = struct;

%% Poincare plot

[sd1, sd2] = poincare(nni, 'plot', false);
hrv_nl.SD1 = sd1;
hrv_nl.SD2 = sd2;

%% === DFA-based Nonlinear metrics (short and long-term scaling exponents, alpha1 & alpha2)

% Calcualte DFA
[~, ~, alpha1, alpha2] = dfa(tm_nni, nni, 'plot', should_plot);
fig_dfa = gcf;
fig_ax_dfa = gca;

% Save the scaling exponents
hrv_nl.alpha1 = alpha1;
hrv_nl.alpha2 = alpha2;

%% === Beta: Spectral power-law exponent

% Select window size for spectrum calculation. Since we need a minimal frequency resolution of
% beta_band(1), so the minimal window we need to resolve this frequency is
t_win_minimum = 1/beta_band(1);

% Take five times the minimal window for better resolution.
% We'll average the spectrums from each window to reduce noise.
window_minutes = floor(5 * t_win_minimum / 60);

% Make sure the window isn't longer than the signal
if ((tm_nni(end) / 60) < window_minutes)
    window_minutes = [];
end

% Calculate spectrum
[ ~, pxx, f_axis ] = hrv_freq(nni, tm_nni, 'methods', {'lomb'}, 'window_minutes', window_minutes);

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
    hfigure = figure;

    % Move the DFA plot into a subplot
    hsub1 = subplot(3, 1, 1);
    hsub1_pos = get(hsub1,'Position');
    delete(hsub1);
    set(fig_ax_dfa,'Parent',hfigure,'Position',hsub1_pos);
    delete(fig_dfa);

    % Plot the spectrum (only plot every x samples)
    f_beta_plot = f_axis(beta_band_idx);
    pxx_beta_plot = pxx(beta_band_idx);
    decimation_factor = 1;
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
