function [ hrv_nl ] = hrv_nonlinear( nni, varargin )
%HRV_NONLINEAR Calcualte non-linear HRV metrics.
%   Inputs:
%       - nni: RR/NN intervals, in seconds.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - beta_band: A 2-element vector specifying the frequency range (in Hz) to use for
%             calculating the beta parameter. Default: [0.003, 0.04].
%
%   Output:
%       - hrv_nl: Struct containing the following HRV metrics:
%           - SD1: Poincare plot SD1 descriptor (std. dev. of intervals along the line perpendicular
%             to the line of identity).
%           - SD2: Poincare plot SD2 descriptor (std. dev. of intervals along the line of identity).
%

%% === Input
DEFAULT_BETA_BAND = rhrv_default('hrv_nl.beta_band', [0.003, 0.04]); % hz
DEFAULT_MSE_MAX_SCALE = rhrv_default('mse.mse_max_scale', 20);
DEFAULT_SAMPEN_R = rhrv_default('mse.sampen_r', 0.2); % percent of std. dev.
DEFAULT_SAMPEN_M = rhrv_default('mse.sampen_m', 2);

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('nni', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('beta_band',  DEFAULT_BETA_BAND, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('mse_max_scale', DEFAULT_MSE_MAX_SCALE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_r', DEFAULT_SAMPEN_R, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sampen_m', DEFAULT_SAMPEN_M, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(nni, varargin{:});
beta_band = p.Results.beta_band;
mse_max_scale = p.Results.mse_max_scale;
sampen_r = p.Results.sampen_r;
sampen_m = p.Results.sampen_m;
should_plot = p.Results.plot;

% Create output struct
hrv_nl = struct;

%% Preprocess

% Calculate zero-based interval time axis
nni = nni(:);
tnn = [0; cumsum(nni(1:end-1))];

%% Poincare plot

[sd1, sd2] = poincare(nni, 'plot', false);
hrv_nl.SD1 = sd1;
hrv_nl.SD2 = sd2;

%% === DFA-based Nonlinear metrics (short and long-term scaling exponents, alpha1 & alpha2)

% Calcualte DFA
[~, ~, alpha1, alpha2] = dfa(tnn, nni, 'plot', should_plot);
if should_plot
    fig_dfa = gcf;
    fig_ax_dfa = gca;
end

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
if ((tnn(end) / 60) < window_minutes)
    window_minutes = [];
end

% Calculate spectrum
[ ~, pxx, f_axis ] = hrv_freq(nni, 'methods', {'lomb'}, 'window_minutes', window_minutes);

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

% Save the first MSE value (this is the sample entropy).
hrv_nl.SampEn = mse_values(1);

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
    plot(scale_axis, mse_values, '--ko', 'MarkerSize', 7); grid on;
    xlabel('Scale factor'); ylabel('Sample Entropy');
    legend(['MSE, ', 'r=' num2str(sampen_r), ' m=' num2str(sampen_m)]);
end
