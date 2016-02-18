function [ Sxx, f_axis, a ] = psd_yulewalker( x, order, fs )
%PSD_YULEWALKER Spectral density using Yule-Walker autoregressive model.
%   x - input time series
%   order - AR model order to use
%   fs - if scalar: Sampling frequecy of x. If vector: the frequencies on
%        which to evaluate the spectrum. In the latter case fs must be evenly
%        spaced and fs(end) must be the nyquist frequency.

%   Sxx - PSD estimate for x
%   f - frequency axis for Sxx. Will be equal to fs if fs was a vector and
%       otherwise will be a vector of (-fs/2, fs/2] in jumps of
%       fs/length(x).
%   a - Yule-walker model parameters vector

% X-axis
if (isscalar(fs))
    N = length(x);
    % note: nyquist freq is at end of positive side
    f_axis = ((-fs/2 + fs/N):fs/N:(fs/2))';
else
    N = length(fs);
    f_axis = fs;
    fs = max(fs)*2;
end

%% Fit AR Model
[Rxx_, lags_] = xcorr(x, order, 'biased');

% Yule-Walker
r_ = -Rxx_(lags_ >= 1 & lags_ <= order);
R_ = toeplitz(Rxx_(lags_ >= 0 & lags_ <= order-1));
a = [1; R_ \ r_];

% Calculate analytical spectrum from AR model
theta_ = f_axis * pi / (fs/2);
z_ = exp(1j .* theta_);
Az_ = polyval(fliplr(a), 1./z_);
Sxx = 1 ./ (abs(Az_).^2); % Sxx is equivalent to abs(fft(x).^2)

% Scale like a periodogram
Sxx = (1/(fs * N)) * Sxx;

% Take only the non negative freqs
f_positive = find(f_axis >= 0);
f_axis = f_axis(f_positive);
Sxx = Sxx(f_positive);

% Multiply by 2 to maintain total power (except at DC and Nyq.)
Sxx(2:end-1) = 2 * Sxx(2:end-1);

% Plot if no output arguments
if (nargout == 0)
    figure;
    semilogy(f_axis, Sxx);
    grid on; xlabel('f [Hz]'); ylabel('S_{xx}(f) [db/Hz]');
end
end

