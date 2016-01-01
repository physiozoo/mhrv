function [ Sxx, f, a ] = psd_yulewalker( x, fs, order )
%PSD_YULEWALKER Summary of this function goes here
%   Detailed explanation goes here

% X-axis
N = length(x);
%f = ((-fs/2):fs/N:(fs/2 - fs/N))';
f = ((-fs/2 + fs/N):fs/N:(fs/2))'; % note: nyquist freq is at end of positive side

%% Fit AR Model
[Rxx_, lags_] = xcorr(x, order, 'biased');

% Yule-Walker
r_ = -Rxx_(lags_ >= 1 & lags_ <= order);
R_ = toeplitz(Rxx_(lags_ >= 0 & lags_ <= order-1));
a = [1; R_ \ r_];

% Calculate analytical spectrum from AR model
theta_ = f * pi / (fs/2);
z_ = exp(1j .* theta_);
Az_ = polyval(fliplr(a), 1./z_);
Sxx = 1 ./ (abs(Az_).^2); % Sxx is equivalent to abs(fft(x).^2)

% Take one side (only positive freqs)
f_positive = ceil(N/2):N;
Sxx = Sxx(f_positive);
f = f(f_positive);

% Scale like a periodogram
Sxx = (1/(fs * N)) * Sxx;
Sxx(2:end-1) = 2 * Sxx(2:end-1); % multiple by 2 to maintain total power (except at DC and Nyq.)

% Plot if no output arguments
if (nargout == 0)
    figure;
    semilogy(f, Sxx);
    grid on; xlabel('f [Hz]'); ylabel('S_{xx}(f) [db/Hz]');
end
end

