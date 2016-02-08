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
qrs = arrayfun(@rqrs_helper, gqrs_detections);

    function [new_qrs_idx] = rqrs_helper(qrs_idx)
        max_win_idx = min(length(sig), qrs_idx + window_size_samples);
        sig_win = sig(qrs_idx:max_win_idx);
        [~, win_max_idx] = max(sig_win);
        new_qrs_idx = qrs_idx + win_max_idx - 1;
    end

% Plot if no output arguments
if (nargout == 0)
    figure;
    plot(tm, sig); hold on; grid on;
    plot(tm(qrs), sig(qrs,1), 'rx');
end

end