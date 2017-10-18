function [ qrs, outliers, tm, sig, Fs ] = rqrs( rec_name, varargin )
%RQRS R-peak detection in ECG signals, based on 'gqrs' and 'gqpost'.
%   RQRS Finds R-peaks in PhysioNet-format ECG records. It uses the 'gqrs' and 'gqpost' programs
%   from the PhysioNet WFDB toolbox, to find the QRS complexes. Then, it searches forward in a small
%   window to find the R-peak.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - 'ecg_channel': Number of ecg signal in the record (default [], i.e. auto-detect signal).
%           - 'gqconf': Path to a gqrs config file to use. This allows adapting the algorithm for
%                       different signal and/or animal types (default is '', i.e. no config file).
%           - 'gqpost': Whether to run the 'gqpost' tool to find erroneous detections (default
%                       false).
%           - 'from': Number of first sample to start detecting from (default 1)
%           - 'to': Number of last sample to detect until (default [], i.e. end of signal)
%           - 'window_size_sec': Size of the forward-search window, in seconds.
%           - 'plot': true/false whether to generate a plot. Defaults to true if no output arguments
%                   were specified.
%   Output:
%       - qrs: Vector of sample numbers where the an onset of a QRS complex was found.
%       - outliers: Vector of sample numbers which were marked by gqpost as suspected false
%                   detections.
%       - tm: Time vector (x-axis) of the input signal.
%       - sig: The input signal values.
%       - Fs: The input signals sampling frequency.

%% === Input

% Defaults
DEFAULT_ECG_CHANNEL = [];
DEFAULT_GQPOST = rhrv_get_default('rqrs.use_gqpost', 'value');
DEFAULT_GQCONF = rhrv_get_default('rqrs.gqconf', 'value');
DEFAULT_TO_SAMPLE = [];
DEFAULT_FROM_SAMPLE = 1;
DEFAULT_WINDOW_SIZE_SECONDS = rhrv_get_default('rqrs.window_size_sec', 'value');

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('ecg_channel', DEFAULT_ECG_CHANNEL, @(x) isnumeric(x) && isscalar(x));
p.addParameter('gqpost', DEFAULT_GQPOST, @(x) islogical(x) && isscalar(x));
p.addParameter('gqconf', DEFAULT_GQCONF, @isstr);
p.addParameter('from', DEFAULT_FROM_SAMPLE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('to', DEFAULT_TO_SAMPLE, @(x) isnumeric(x) && (isscalar(x)||isempty(x)));
p.addParameter('window_size_sec', DEFAULT_WINDOW_SIZE_SECONDS, @isnumeric);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
ecg_channel = p.Results.ecg_channel;
gqpost = p.Results.gqpost;
gqconf = p.Results.gqconf;
from_sample = p.Results.from;
to_sample = p.Results.to;
window_size_sec = p.Results.window_size_sec;
should_plot = p.Results.plot;

%% Run gqrs

% Make sure we have an ECG channel in the record
if (isempty(ecg_channel))
    ecg_channel = get_signal_channel(rec_name);
    if (isempty(ecg_channel))
        error('Failed to find an ECG channel in the record %s', rec_name);
    end
end

[gqrs_detections, gqrs_outliers] = gqrs(rec_name, 'ecg_channel', ecg_channel,...
                                        'gqpost', gqpost, 'gqconf', gqconf,...
                                        'from', from_sample, 'to', to_sample);

%% Read Signal
[tm, sig, Fs] = rdsamp(rec_name, ecg_channel, 'from', from_sample, 'to', to_sample);

%% Augment gqrs detections

if (~isempty(gqrs_outliers))
    % put outliers in a map to easily check if an index is an outlier
    outliers_map = containers.Map(gqrs_outliers, ones(size(gqrs_outliers)));
else
    outliers_map = containers.Map;
end

window_size_samples = ceil(window_size_sec * Fs);
if (window_size_samples > 0)
    qrs = arrayfun(@rqrs_helper, gqrs_detections);
else
    qrs = gqrs_detections;
end

% Helper function for augmenting the qrs detections
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

%% Plot
if (should_plot)
    figure;
    plot(tm, sig); hold on; grid on;
    plot(tm(qrs), sig(qrs,1), 'rx');
    xlabel('time (s)'); ylabel ('ECG (mV)');

    if (~isempty(outliers))
        plot(tm(outliers), sig(outliers,1), 'ko');
        legend('signal', 'qrs detections', 'suspected outliers');
    else
        legend('signal', 'qrs detections');
    end
end

end
