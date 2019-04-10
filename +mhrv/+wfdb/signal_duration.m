function [ t_max, h, m, s, ms ] = signal_duration( N, Fs )
%SIGNAL_DURATION Calculates the duration of a signal.
%   Input
%       N: Number of samples
%       Fs: Sampling frequency
%   Output:
%       t_max: total duration in seconds.
%       h: Hours component
%       m: Minutes component
%       s: Seconds component
%       ms: Milliseconds component
%

t_max = N / Fs;

h  = mod(floor(t_max / 3600), 60);
m  = mod(floor(t_max / 60), 60);
s  = mod(floor(t_max), 60);
ms = floor(mod(t_max, 1)*1000);

end

