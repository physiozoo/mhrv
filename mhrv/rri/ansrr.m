function [ rri_out ] = ansrr( rri, freqs, varargin )
%Add Noised Sines to RR interval time series. This function generates a signal
%of sines embedded in gaussian white noise and adds it to an RR interval time
%series.
%
%:param rri: RR-intervals values in seconds.
%:param freqs:  Vector containing desired sine frequencies, in Hz.
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - var_r: Desired variance of the RR intervals. Can be used the scale the
%     intervals before adding the noised sines. Leave empty to forgo scaling.
%   - mix: Mixture ratio between the given RR intervals and the generated
%     sines.  Default: 0.5 i.e. sines will have alf the variance of the RR
%     intervals (after scaling).
%   - snr: Signal to Noise ratio of the white gaussian noise that will be added
%     to the sines. Default: 2.
%
%:returns:
%
%   - rri_out: RR intervals after adding noised sines.
%

%% Input

% Defaults
DEFAULT_RRI_VARIANCE = [];
DEFAULT_SNR = 2;
DEFAULT_MIXTURE_RATIO = 0.5;
DEFAULT_FS = [];

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('freqs', @(x) isnumeric(x));
p.addParameter('var_r', DEFAULT_RRI_VARIANCE, @(x) isempty(x)||isscalar(x));
p.addParameter('snr', DEFAULT_SNR, @isscalar);
p.addParameter('mix', DEFAULT_MIXTURE_RATIO, @(x) isscalar(x) && x>=0 && x<=10);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rri, freqs, varargin{:});
var_r = p.Results.var_r;
snr = p.Results.snr;
mix_ratio = p.Results.mix;
should_plot = p.Results.plot;

%% Generate

% Create axes
trr = [0; cumsum(rri(1:end-1))];
Fs = 1/mean(diff(trr));
T = max(trr)+1/Fs; % sec
t_axis = 0 : 1/Fs : (T-1/Fs);
N = length(t_axis);

% Create Sines signal
x = zeros(1,N);
for f = freqs
    x = x + sin(2*pi*f .* t_axis);
end

% Scale rri to desired variance
if isempty(var_r)
    var_r = var(rri);
end
sigma_r = sqrt(var_r);
mu_r = mean(rri);
rri_scaled = (rri-mu_r)/std(rri) .* sigma_r + mu_r;

% Scale x using the variance of the RR intervals and the mix ratio
sigma_x = sigma_r * mix_ratio;
x = (x-mean(x))/std(x) .* sigma_x;

% Add WGN (SNR is relative to the variance of the sine signal)
sigma_n = (1/snr) * sigma_x;
y = x + sigma_n.*randn(size(x));

% Resample at the RR interval times
y = interp1(t_axis,y,trr);

% Create output mixture
rri_out = rri_scaled + y;

%% Plots

if should_plot
    f1 = figure;
    subplot(3,1,1);
    plot(t_axis, x, trr, y, trr, rri, trr, rri_out);
    xlabel('time (sec)');
    legend(sprintf('x (\\sigma=%.3f)',sigma_x), 'y',sprintf('RR (\\sigma=%.3f)', sigma_r), sprintf('RR + y (\\sigma=%.3f)', std(rri_out)));

    % Spectrum
    df = 1/T; f_max = Fs/2;
    f_axis = df : df : f_max;
    welch_win = hamming(floor(N/2));
    pxx_x = pwelch(x, welch_win, length(welch_win)/2, f_axis, Fs);
    pxx_y = pwelch(y, welch_win, length(welch_win)/2, f_axis, Fs);

    subplot(3,1,2);
    plot(f_axis, pxx_x, 'DisplayName', 'PXX_x'); hold on;
    plot(f_axis, pxx_y, 'DisplayName', 'PXX_y'); hold on;
    % f2 = figure; plot(f_axis, pxx_y, 'LineWidth', 1.5, 'DisplayName', 'Simulated ANS'); hold on;
    for f = freqs
        plot(f, pxx_y(find(abs(f_axis-f)<df/2)), 'DisplayName', sprintf('%.2fHz', f),...
            'LineStyle', 'none', 'Marker', 'V', 'MarkerSize', 8);
    end
    plot(f_axis, ones(size(f_axis)).*(sigma_n^2), 'DisplayName', '\sigma^{2}_{n}', 'LineWidth', 1.5, 'LineStyle','--', 'Color', 'black');
    xlabel('Frequency (Hz)'); ylabel('PSD');
    grid on;
    set(gca, 'XScale','log','YScale','log');
    legend('show', 'Location', 'northwest');

    % MSE
    figure(f1);
    ax = subplot(3,1,3);
    [~,~,mse_pd] = mse(y);
    plot_mse(ax, mse_pd);
    
    figure;
    plot(f_axis, pxx_y, 'DisplayName', 'ANS Model', 'LineWidth', 2); hold on;
    % f2 = figure; plot(f_axis, pxx_y, 'LineWidth', 1.5, 'DisplayName', 'Simulated ANS'); hold on;
    for f = freqs
        plot(f, pxx_y(find(abs(f_axis-f)<df/2)), 'DisplayName', sprintf('%.2fHz', f),...
            'LineStyle', 'none', 'Marker', 'V', 'MarkerSize', 8);
    end
    plot(f_axis, ones(size(f_axis)).*(sigma_n^2), 'DisplayName', '\sigma^{2}_{n}', 'LineWidth', 1.5, 'LineStyle','--', 'Color', 'black');
    xlabel('Frequency (Hz)'); ylabel('PSD');
    grid on;
    set(gca, 'XScale','log','YScale','log', 'XLim', [1e-3,1e0], 'YLim', [1e-6,1e-1]);
    legend('show', 'Location', 'northwest');
end

end

