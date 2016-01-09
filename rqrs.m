function [ qrs, tm, sig, Fs ] = rqrs( rec_name, varargin )
%RQRS R-peak detection in ECG signals, based on 'gqrs'
%   Detailed explanation goes here

%% === Input

% Defaults
DEFAULT_WINDOW_SIZE_SECONDS = 0.1;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('window_size_sec', DEFAULT_WINDOW_SIZE_SECONDS, @isnumeric);

% Get input
p.parse(rec_name, varargin{:});
window_size_sec = p.Results.window_size_sec;

%% === Run gqrs
gqrs_detections = gqrs(rec_name, varargin{:});

% === Read Signal
ecg_col = get_signal_channel(rec_name);
[tm, sig, Fs] = rdsamp(rec_name, ecg_col);
window_size_samples = ceil(window_size_sec * Fs);

% === Augment gqrs detections
qrs = zeros(size(gqrs_detections));
parfor ii = 1:length(qrs)
    detection_idx = gqrs_detections(ii);
    max_window_idx = min(length(sig), detection_idx + window_size_samples);
    sig_window = sig(detection_idx:max_window_idx);
    [~, window_max_idx] = max(sig_window);
    qrs(ii) = detection_idx + window_max_idx - 1;
end
