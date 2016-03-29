function [ qrs, outliers ] = rqrs_augment( gqrs_detections, gqrs_outliers, t_sig, sig, varargin )
%RQRS R-peak detection in ECG signals, based on 'gqrs'
%   Detailed explanation goes here

%% === Input

% Defaults
DEFAULT_WINDOW_SIZE_SECONDS = 0.1;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('gqrs_detections', @isvector);
p.addRequired('gqrs_outliers', @(x) isempty(x) || isvector(x));
p.addRequired('t_sig', @isvector);
p.addRequired('sig', @isvector);
p.addParameter('window_size_sec', DEFAULT_WINDOW_SIZE_SECONDS, @isnumeric);

% Get input
p.parse(gqrs_detections, gqrs_outliers, t_sig, sig, varargin{:});
window_size_sec = p.Results.window_size_sec;

% === Augment gqrs detections
Fs = 1/(t_sig(2)-t_sig(1));  % Sampling frequency
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

end