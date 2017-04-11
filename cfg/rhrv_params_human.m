function [] = rhrv_params_human(defaults, cfg_path)
%RHRV_PARAMS_HUMAN Default parameter values of the rhrv toolbox for human ECG data.

%% Peak detection
defaults('rqrs.gqconf') = [cfg_path filesep 'gqrs.default.conf'];
defaults('rqrs.use_gqpost') = true;
defaults('rqrs.window_size_sec') = 0.056; % 80% of .07, the average human QRS duration

%% RR Interval filtering
defaults('filtrr.filter_poincare') = true;
defaults('filtrr.filter_lowpass') = true;
defaults('filtrr.win_samples') = 10; % samples
defaults('filtrr.win_percent') = 20; % percentage [0-100]

%% Time-domain HRV metrics
defaults('hrv_time.pnn_thresh_ms') = 50;

%% Frequency HRV metrics
defaults('hrv_freq.methods') = {'lomb', 'ar', 'welch'};
defaults('hrv_freq.band_factor') = 1.0;
defaults('hrv_freq.vlf_band') = [0.003, 0.04];
defaults('hrv_freq.lf_band') = [0.04,  0.15];
defaults('hrv_freq.hf_band') = [0.15,  0.4];
defaults('hrv_freq.window_minutes') = 5;
defaults('hrv_freq.ar_order') = 24;
defaults('hrv_freq.welch_overlap') = 50; % percent
defaults('hrv_freq.detrend_order') = 1;

%% Nonlinear HRV metrics
defaults('hrv_nl.beta_band') = [0.003, 0.04]; % hz

%% Poincare
defaults('poincare.sd1_factor') = 2;
defaults('poincare.sd2_factor') = 2;
defaults('poincare.rr_min') = 0.32; % Seconds (187.5 BPM)
defaults('poincare.rr_max') = 1.5;  % Seconds (40 BPM)
defaults('poincare.rr_max_change') = 25; % Percent, max change between adjacent RR intervals

%% DFA
defaults('dfa.n_min') = 4;
defaults('dfa.n_max') = 128;
defaults('dfa.n_incr') = 4;
defaults('dfa.alpha1_range') = [4, 15];
defaults('dfa.alpha2_range') = [16, 128];

%% MSE
defaults('mse.mse_max_scale') = 20;
defaults('mse.sampen_r') = 0.2; % percent of std. dev.
defaults('mse.sampen_m') = 2;
