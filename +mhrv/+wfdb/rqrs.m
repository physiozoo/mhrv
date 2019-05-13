function [ qrs, tm, sig, Fs ] = rqrs( rec_name, varargin )
%R-peak detection in ECG signals, based on ``gqrs`` and ``gqpost``.  ``rqrs``
%Finds R-peaks in PhysioNet-format ECG records. It uses the ``gqrs`` and
%``gqpost`` programs from the PhysioNet WFDB toolbox, to find the QRS
%complexes. Then, it searches forward in a small window to find the R-peak.
%
%:param rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if
%   the record files (both 100.dat and 100.hea) are in a folder named 'db/mitdb'
%   relative to MATLABs pwd.
%
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - ecg_channel: Number of ecg signal in the record (default [], i.e.
%     auto-detect signal).
%   - gqconf: Path to a gqrs config file to use. This allows adapting the
%     algorithm for different signal and/or animal types (default is '', i.e. no
%     config file).
%   - gqpost: Whether to run the 'gqpost' tool to find and remove possibly
%     erroneous detections.
%   - from: Number of first sample to start detecting from (default 1)
%   - to: Number of last sample to detect until (default [], i.e. end of signal)
%   - window_size_sec: Size of the forward-search window, in seconds.
%   - plot: true/false whether to generate a plot. Defaults to true if no
%     output arguments were specified.
%
%:returns:
%   - qrs: Vector of sample numbers where the an onset of a QRS complex was found.
%   - tm: Time vector (x-axis) of the input signal.
%   - sig: The input signal values.
%   - Fs: The input signals sampling frequency.

import mhrv.defaults.*;
import mhrv.wfdb.*;

%% === Input

% Defaults
DEFAULT_ECG_CHANNEL = [];
DEFAULT_GQPOST = mhrv_get_default('rqrs.use_gqpost', 'value');
DEFAULT_GQCONF = mhrv_get_default('rqrs.gqconf', 'value');
DEFAULT_TO_SAMPLE = [];
DEFAULT_FROM_SAMPLE = 1;
DEFAULT_WINDOW_SIZE_SECONDS = mhrv_get_default('rqrs.window_size_sec', 'value');

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('header_info', [], @(x) isempty(x) || isstruct(x));
p.addParameter('ecg_channel', DEFAULT_ECG_CHANNEL, @(x) isnumeric(x) && isscalar(x));
p.addParameter('gqpost', DEFAULT_GQPOST, @(x) islogical(x) && isscalar(x));
p.addParameter('gqconf', DEFAULT_GQCONF, @isstr);
p.addParameter('from', DEFAULT_FROM_SAMPLE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('to', DEFAULT_TO_SAMPLE, @(x) isnumeric(x) && (isscalar(x)||isempty(x)));
p.addParameter('window_size_sec', DEFAULT_WINDOW_SIZE_SECONDS, @isnumeric);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
header_info = p.Results.header_info;
ecg_channel = p.Results.ecg_channel;
gqpost = p.Results.gqpost;
gqconf = p.Results.gqconf;
from_sample = p.Results.from;
to_sample = p.Results.to;
window_size_sec = p.Results.window_size_sec;
should_plot = p.Results.plot;

% Validate header info
if isempty(header_info)
    header_info = wfdb_header(rec_name);
elseif ~strcmp(rec_name, header_info.rec_name)
    error('Provided header_info was for a different record');
end

%% Run gqrs

% Make sure we have an ECG channel in the record
if (isempty(ecg_channel))
    ecg_channel = get_signal_channel(rec_name, 'header_info', header_info);
    if (isempty(ecg_channel))
        error('Failed to find an ECG channel in the record %s', rec_name);
    end
end

[gqrs_detections, gqrs_outliers] = gqrs(rec_name, 'ecg_channel', ecg_channel,...
                                        'gqpost', gqpost, 'gqconf', gqconf,...
                                        'from', from_sample, 'to', to_sample);

%% Read Signal
[tm, sig, Fs] = rdsamp(rec_name, ecg_channel, 'header_info', header_info, 'from', from_sample, 'to', to_sample);

%% Augment gqrs detections

% Remove outliers
gqrs_detections = setdiff(gqrs_detections, gqrs_outliers);

window_size_samples = ceil(window_size_sec * Fs);
if (window_size_samples > 0)
    [qrs_max, qrs_min] = arrayfun(@rqrs_helper, gqrs_detections);

    % Handling cases of positive vs. negative ECG polarity:
    % Calculate median abs. difference between the signal value at the gqrs
    % detection point (which is usually the Q-wave) and the
    % maximal/minimal value in the relevant window. Take either all max
    % points or all min points depending on which value is larger.
    gqrs_values = sig(gqrs_detections);
    diff_to_max = median(abs(gqrs_values - sig(qrs_max)));
    diff_to_min = median(abs(gqrs_values - sig(qrs_min)));

    if diff_to_max > diff_to_min
        qrs = qrs_max;
    else
        qrs = qrs_min;
    end
else
    qrs = gqrs_detections;
end

% Helper function for augmenting the qrs detections
function [new_qrs_max, new_qrs_min] = rqrs_helper(qrs_idx)
    max_win_idx = min(length(sig), qrs_idx + window_size_samples);
    sig_win = sig(qrs_idx:max_win_idx);

    [~, win_max_idx] = max(sig_win);
    [~, win_min_idx] = min(sig_win);

    new_qrs_max = qrs_idx + win_max_idx - 1;
    new_qrs_min = qrs_idx + win_min_idx - 1;
end

%% Plot
if (should_plot)
    figure;
    plot(tm, sig); hold on; grid on;
    plot(tm(qrs), sig(qrs,1), 'rx');
    xlabel('time (s)'); ylabel ('ECG (mV)');
    legend('signal', 'qrs detections');
end

end
