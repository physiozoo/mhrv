function [ qrs, tm, sig, Fs, outliers ] = rqrs( rec_name, varargin )
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
ecg_col = get_signal_channel(rec_name);
[gqrs_detections, gqrs_outliers] = gqrs(rec_name, 'ecg_col', ecg_col, varargin{:});

% === Read Signal
[tm, sig, Fs] = rdsamp(rec_name, ecg_col);

% === Augment gqrs detections
window_size_samples = ceil(window_size_sec * Fs);
if (~isempty(gqrs_outliers))
    outliers_map = containers.Map(gqrs_outliers, ones(size(gqrs_outliers))); % put outliers in a map to easily check if an index is an outlier
else
    outliers_map = containers.Map;
end

if (window_size_samples > 0)
    qrs = arrayfun(@rqrs_helper, gqrs_detections);
else
    qrs = gqrs_detections;
end

    function [new_qrs_idx] = rqrs_helper(qrs_idx)
        max_win_idx = min(length(sig), qrs_idx + window_size_samples);
        sig_win = sig(qrs_idx:max_win_idx);
        [~, win_max_idx] = max(sig_win);
        new_qrs_idx = qrs_idx + win_max_idx - 1;
        
        % Move the outlier index if current detection is an outlier
        if (outliers_map.isKey(qrs_idx))
            outliers_map.remove(qrs_idx);
            outliers_map(new_qrs_idx) = 1;
        end
    end

% Get the updated outlier indices
outliers = cell2mat(outliers_map.keys);

% Plot if no output arguments
if (nargout == 0)
    figure;
    plot(tm, sig); hold on; grid on;
    plot(tm(qrs), sig(qrs,1), 'rx');
        
    if (~isempty(outliers))
        plot(tm(outliers), sig(outliers,1), 'ko');
        legend('signal', 'qrs detections', 'suspected outliers');
    else
        legend('signal', 'qrs detections');
    end
end

end