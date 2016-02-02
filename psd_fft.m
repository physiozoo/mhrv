function [ psdx, f ] = psd_fft( x, fs )
%PSD_YULEWALKER Summary of this function goes here
%   Detailed explanation goes here

% X-axis
N = length(x);
f = (0:fs/N:(fs/2))'; % note: nyquist freq is at end of positive side

% Compute periodogram from FFT
xdft = fft(x);
xdft = xdft(1:floor(N/2)+1);
psdx = (1/(fs * N)) * abs(xdft).^2;
psdx(2:end-1) = 2 * psdx(2:end-1);

% Plot if no output arguments
if (nargout == 0)
    figure;
    semilogy(f, psdx);
    grid on; xlabel('f [Hz]'); ylabel('S_{xx}(f) [db/Hz]');
end
end

