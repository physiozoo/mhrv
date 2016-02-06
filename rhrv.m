function [ hrv_td, hrv_fd ] = rhrv( rec_name, varargin )
%RHRV Heart Rate Variability metrics
%   Detailed explanation goes here

%% === Input

% Defaults
DEFAULT_TOLERANCE_BPM = 10;
DEFAULT_F_MAX = 0.4; %Hz
DEFAULT_DETREND_ORDER = 10;
DEFAULT_AR_ORDER = 24;
DEFAULT_WINDOW_MINUTES = 5;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);

% Preprocessing parameters
p.addParameter('tol_bpm', DEFAULT_TOLERANCE_BPM, @isnumeric);
p.addParameter('detrend_order', DEFAULT_DETREND_ORDER, @isnumeric);

% Freq domain parameters
p.addParameter('f_max', DEFAULT_F_MAX, @isnumeric);
p.addParameter('ar_order', DEFAULT_AR_ORDER, @isnumeric);
p.addParameter('window_minutes', DEFAULT_WINDOW_MINUTES, @isnumeric);

% Get input
p.parse(rec_name, varargin{:});
tol_bpm = p.Results.tol_bpm;
f_max = p.Results.f_max;
detrend_order = p.Results.detrend_order;
ar_order = p.Results.ar_order;
window_minutes = p.Results.window_minutes;

%% === Calculate HRV metrics

% First, find R-peaks (also returns the signal)
[qrs, tm, sig, fs] = rqrs(rec_name);

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

%% === Time Domain
hrv_td = hrv_time(rri);

%% === Freq domain
[ hrv_fd, pxx_lomb, f_lomb ] = hrv_freq(rri, tm_rri, 'method', 'lomb');

% Detrend and zero mean
rri = rri - mean(rri);
[poly, ~, poly_mu] = polyfit(tm_rri, rri, detrend_order);
rri_trend = polyval(poly, tm_rri, [], poly_mu);
rri = rri - rri_trend;

%% === Display output if no output args
if (nargout == 0)
    % Calculate with AR method to plot both
    [ ~, pxx_ar, ~ ] = hrv_freq(rri, tm_rri, 'method', 'ar');

    % Plot RR and Spectrum
    close all;
    set(0,'DefaultAxesFontSize',14);
    figure;
    subplot(2,1,1); plot(tm_rri, rri);
    xlabel('Time [s]'); ylabel('RR-interval [s]');
    subplot(2,1,2); semilogy(f_lomb, [pxx_lomb, pxx_ar]); grid on; hold on;
    xlabel('Frequency [hz]'); ylabel('Power Density [s^2/Hz]');
    xlim([0,f_max*1.01]); ylim([1e-7, 1]);
    
    % vertical lines
    LF_band = [0.04, 0.15];
    HF_band = [0.15, f_max];
    yrange = get(gca,'ylim');
    line(LF_band(1) * ones(1,2), yrange, 'LineStyle', ':', 'Color', 'red');
    line(HF_band(1) * ones(1,2), yrange, 'LineStyle', ':', 'Color', 'red');
    line(HF_band(2) * ones(1,2), yrange, 'LineStyle', ':', 'Color', 'red');
    
    disp(hrv_td);
    disp(hrv_fd);
end
