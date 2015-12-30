function [ hrv, rri ] = rhrv(  rec_name, varargin )
%RHRV Heart Rate Variability metrics
%   Detailed explanation goes here

%% === Input

% Defaults

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);

% Get input
p.parse(rec_name, varargin{:});

%% === Calculate HRV metrics

% First, find R-peaks (also returns the signal)
[qrs, tm, sig, Fs] = rqrs(rec_name);

% Init output structure
hrv = struct;

% RR-intervals are the time-difference between R-Peaks
rri = diff(tm(qrs));
tm_rri = tm(qrs(2:end));

%% === Time Domain Metrics
hrv.AVNN = mean(rri);
hrv.SDNN = sqrt(var(rri));
hrv.RMSSD = sqrt(mean(diff(rri).^2));
hrv.pNN50 = sum(abs(diff(rri)) > 0.05)/length(rri);

%% === Freq domain - Non parametric
f_max = 0.4; % Hz
[pxx_lomb, f] = plomb(rri, tm_rri, f_max); % lomb periodogram

TOT_band = [min(f), max(f)];
ULF_band = [min(f), 0.003];
VLF_band = [0.003, 0.04];
LF_band = [0.04, 0.15];
HF_band = [0.15, max(f)];

hrv.TOT_PWR = bandpower(pxx_lomb,f,TOT_band,'psd');
hrv.ULF_PWR = bandpower(pxx_lomb,f,ULF_band,'psd');
hrv.VLF_PWR = bandpower(pxx_lomb,f,VLF_band,'psd');
hrv.LF_PWR = bandpower(pxx_lomb,f,LF_band,'psd');
hrv.HF_PWR = bandpower(pxx_lomb,f,HF_band,'psd');

%% === Freq domain - Parametric

% resample to obtain uniformly sampled signal
[rri_uni, tm_rri_uni] = resample(rri, tm_rri, Fs);

% L_AR = 150;
% [pxx_ar,~] = pyulear(rri_uni(tm_rri_uni < 590), L_AR, f, Fs); % Yule-Walker AR model

%% === Plot
% Set larger default font 
close all;
set(0,'DefaultAxesFontSize',14);
figure;
subplot(2,1,1); plot(tm_rri, rri);
xlabel('Time [s]'); ylabel('RR-interval [s]');
subplot(2,1,2); plot(f, [pxx_lomb]); %, pxx_ar]);
xlabel('Frequency [hz]'); ylabel('Power [ms^2]');