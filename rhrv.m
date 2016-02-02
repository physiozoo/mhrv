function [ hrv, rri ] = rhrv( rec_name, varargin )
%RHRV Heart Rate Variability metrics
%   Detailed explanation goes here

%% === Input

% Defaults
DEFAULT_TOLERANCE_BPM = 10;
DEFAULT_F_MAX = 0.4; %Hz
DEFAULT_DETREND_ORDER = 10;
DEFAULT_AR_ORDER = 24;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('tol_bpm', DEFAULT_TOLERANCE_BPM, @isnumeric);
p.addParameter('f_max', DEFAULT_F_MAX, @isnumeric);
p.addParameter('detrend_order', DEFAULT_DETREND_ORDER, @isnumeric);
p.addParameter('ar_order', DEFAULT_AR_ORDER, @isnumeric);

% Get input
p.parse(rec_name, varargin{:});
tol_bpm = p.Results.tol_bpm;
f_max = p.Results.f_max;
detrend_order = p.Results.detrend_order;
ar_order = p.Results.ar_order;

%% === Calculate HRV metrics

% First, find R-peaks (also returns the signal)
[qrs, tm, sig, fs] = rqrs(rec_name);

% Init output structure
hrv = struct;

% RR-intervals are the time-difference between R-Peaks
rri = diff(tm(qrs));
tm_rri = tm(qrs(1:end-1));

% instantaneus heart rate (bpm)
ihr = 60 ./ rri;

% calculate an average ihr signal
nfilt = 10;
b_fir = 1/nfilt * ones(nfilt,1);
ihr_lp = filtfilt(b_fir, 1, ihr); % use filtfilt for zero-phase

% remove outliers using x bpm tolerance
outliers_idx = find(abs(diff(ihr)) > tol_bpm);
outliers_idx = unique([outliers_idx; find(abs(ihr - ihr_lp) > tol_bpm)]);
%figure; plot(tm_rri,ihr,'b-', tm_rri,ihr_lp,'r-', tm_rri,ihr_lp-tol_bpm,'k.', tm_rri,ihr_lp+tol_bpm,'k.', tm_rri(outliers_idx),ihr_lp(outliers_idx),'kx');

rri(outliers_idx) = [];
tm_rri(outliers_idx) = [];

%% === Time Domain Metrics
hrv.AVNN = mean(rri);
hrv.SDNN = sqrt(var(rri));
hrv.RMSSD = sqrt(mean(diff(rri).^2));
hrv.pNN50 = sum(abs(diff(rri)) > 0.05)/(length(rri)-1);

%% === Freq domain - Parametric

% Detrend and zero mean
rri = rri - mean(rri);
[poly, ~, poly_mu] = polyfit(tm_rri, rri, detrend_order);
rri_trend = polyval(poly, tm_rri, [], poly_mu);
rri = rri - rri_trend;

% resample to obtain uniformly sampled signal
fs_rri = ceil(2*f_max); %Hz
[rri_uni, tm_rri_uni] = resample(rri, tm_rri, fs_rri, 1, 1);

% Yule-Walker AR model
[pxx_ar, f_ar] = psd_yulewalker(rri_uni, fs_rri, ar_order);

%% === Freq domain - Non parametric

% lomb periodogram, evaluated at frequencies in f_ar
[pxx_lomb, f_lomb] = plomb(rri, tm_rri, f_ar);

TOT_band = [min(f_lomb), f_max];
ULF_band = [min(f_lomb), 0.003];
VLF_band = [0.003, 0.04];
LF_band = [0.04, 0.15];
HF_band = [0.15, f_max];

hrv.TOT_PWR = bandpower(pxx_lomb,f_lomb,TOT_band,'psd');
hrv.ULF_PWR = bandpower(pxx_lomb,f_lomb,ULF_band,'psd');
hrv.VLF_PWR = bandpower(pxx_lomb,f_lomb,VLF_band,'psd');
hrv.LF_PWR = bandpower(pxx_lomb,f_lomb,LF_band,'psd');
hrv.HF_PWR = bandpower(pxx_lomb,f_lomb,HF_band,'psd');

%% === Plot
% Set larger default font 
close all;
set(0,'DefaultAxesFontSize',14);
figure;
subplot(2,1,1); plot(tm_rri, rri);
xlabel('Time [s]'); ylabel('RR-interval [s]');
subplot(2,1,2); semilogy(f_lomb, [pxx_lomb, pxx_ar]); grid on; hold on;
xlabel('Frequency [hz]'); ylabel('Power Density [s^2/Hz]');
xlim([0,f_max*1.01]); ylim([1e-7, 1]);
%# vertical line
yrange = get(gca,'ylim');
line(LF_band(1) * ones(1,2), yrange, 'LineStyle', ':', 'Color', 'red');
line(HF_band(1) * ones(1,2), yrange, 'LineStyle', ':', 'Color', 'red');
line(HF_band(2) * ones(1,2), yrange, 'LineStyle', ':', 'Color', 'red');