function [] = rhrv_params_canine(defaults, cfg_path)
%RHRV_PARAMS_CANINE Default parameter values of the rhrv toolbox for canine ECG data.

% Load human params (we'll just change what's relevant)
rhrv_params_human(defaults, cfg_path);

%% Peak detection
defaults('rqrs.gqconf') = [cfg_path filesep 'gqrs.billman.conf'];
defaults('rqrs.window_size_sec') = 0.04; % 80% of .05, the average canine QRS duration

%% Time-domain HRV metrics
defaults('hrv_time.pnn_thresh_ms') = 32;

%% Frequency HRV metrics
defaults('hrv_freq.band_factor') = 1.6; % 120/75

%% Nonlinear HRV metrics
defaults('hrv_nl.beta_band') = [0.003, 0.04] .* 1.6; % hz

%% Poincare
defaults('poincare.rr_min') = 0.3; % Seconds (200 BPM)
defaults('poincare.rr_max') = 1.2;  % Seconds (50 BPM)

