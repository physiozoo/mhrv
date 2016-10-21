function [ qrs, outliers ] = rqrs( rec_name, varargin )
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
[tm, sig, ~] = rdsamp(rec_name, ecg_col);

% === Augment gqrs detections
[ qrs, outliers ] = rqrs_augment(gqrs_detections, gqrs_outliers, tm, sig, 'window_size_sec', window_size_sec);

% Plot if no output arguments
if (nargout == 0)
    figure;
    plot(tm, sig); hold on; grid on;
    plot(tm(qrs), sig(qrs,1), 'rx');
    xlabel('time [s]'); ylabel ('ECG [mV]');

    if (~isempty(outliers))
        plot(tm(outliers), sig(outliers,1), 'ko');
        legend('signal', 'qrs detections', 'suspected outliers');
    else
        legend('signal', 'qrs detections');
    end
end

end
