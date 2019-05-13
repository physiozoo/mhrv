function [ sqi ] = qrs_compare( rec_name, varargin )
%Compare R-peak detection algorithm to annotations.  qrs_compare can run a
%r-peak detector on a given physionet record and compare the detections to an
%annotation file. The function assumes that the annotation file has the same
%record name, with a user-configurable file extension. The function supports
%both wfdb format and matlab's 'mat' format for the annotation files.  The
%comparison of the detected QRS locations to the reference annotations is
%performed by calculating a joint-accuracy measure (F1), based on the
%Sensitivity (SE) and Positive-predictivity (PPV) of the test detector's
%annotations [1]_.
%
%:param rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if
%   the record files (both 100.dat and 100.hea) are in a folder named 'db/mitdb'
%   relative to MATLABs pwd.
%           
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - tolerance: Threshold tolerance time, in seconds, for two peak
%     detections to be considered equal.
%   - ann_ext: Extension of annotation
%     file.
%   - ann_format: Format of annotation file. Can be ``wfdb`` or ``mat``.
%   - ecg_channel: Channel number of ecg signal in the record (default [],
%     i.e. auto-detect signal).
%   - qrs_detector: Name of qrs detector to use. Can be ``rqrs`` or ``gqrs``.
%   - plot: true/false whether to generate a plot. Defaults to true if no
%     output arguments were specified.
%
%:returns:
%
%   - sqi: Signal quality indices for the comparison between the detector and annotations.
%
%.. [1] Johnson, A. E. W., Behar, J., et al. (2015).  Multimodal heart beat
%   detection using signal quality indices.  Physiological Measurement, 36, 1–15.
%

import mhrv.wfdb.*;
import mhrv.defaults.*;

%% Input

SUPPORTED_ANN_FORMATS = {'wfdb', 'mat'};
SUPPORTED_QRS_DETECTORS = {'gqrs', 'rqrs'};

% Defaults
DEFAULT_TOLERANCE = 0.15; % 150 ms
DEFAULT_ANN_EXT = 'atr';
DEFAULT_ANN_FORMAT = SUPPORTED_ANN_FORMATS{1};
DEFAULT_ECG_CHANNEL = [];
DEFAULT_QRS_DETECTOR = SUPPORTED_QRS_DETECTORS{1};

% Define input
p = inputParser;
p.addRequired('rec_name', @isstr);
p.addParameter('tolerance', DEFAULT_TOLERANCE, @isnumeric);
p.addParameter('ann_ext', DEFAULT_ANN_EXT, @isstr);
p.addParameter('ann_format', DEFAULT_ANN_FORMAT, @(x) any(cellfun(@(y)strcmp(x,y),SUPPORTED_ANN_FORMATS)));
p.addParameter('ecg_channel', DEFAULT_ECG_CHANNEL, @isnumeric);
p.addParameter('qrs_detector', DEFAULT_QRS_DETECTOR, @(x) any(cellfun(@(y)strcmp(x,y),SUPPORTED_QRS_DETECTORS)));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
tolerance_sec = p.Results.tolerance;
ann_ext = p.Results.ann_ext;
ann_format = p.Results.ann_format;
ecg_channel = p.Results.ecg_channel;
qrs_detector = p.Results.qrs_detector;
should_plot = p.Results.plot;

%% Load the specific record

% Find ECG signal index if it wasn't specified
[default_ecg_channel, Fs, ~] = get_signal_channel(rec_name);
if isempty(ecg_channel)
    if isempty(default_ecg_channel)
        error('No ECG channel found in record %s', rec_name);
    else
        ecg_channel = default_ecg_channel;
    end
end

% Read the signal
[tm, sig, ~] = rdsamp(rec_name, ecg_channel);

%% Load reference QRS annotations

% Get the reference QRS annotations
if strcmp(ann_format, 'wfdb')
    ref_qrs = rdann(rec_name, ann_ext);
else
    % Load annotation file as a matlab .mat file
    loaded_data = load([rec_name '.' ann_ext], '-mat');
    loaded_varnames = fieldnames(loaded_data);

    % Find first loaded variable that contains 'qrs' in it's name
    qrs_idx = find(cellfun(@(x)~isempty(regexpi(x,'qrs')), loaded_varnames));
    ref_qrs = loaded_data.(loaded_varnames{qrs_idx(1)});
    ref_qrs = int32(ref_qrs);
end

%% Detect QRS locations
qrs_detector_func = str2func(qrs_detector);
test_qrs = qrs_detector_func(rec_name, 'ecg_channel', ecg_channel);

%% Compare detections to reference
%  See: https://en.wikipedia.org/wiki/Confusion_matrix

% Convert the tolerance threshold to samples
tolerance_samples = tolerance_sec * Fs;

% Find closest detection in reference QRS for each detection in test QRS
[closest_idx, dist_samples] = dsearchn(ref_qrs, test_qrs);

% If a test detection's the closest reference detection is within the threshold tolerance, it's
% considered a correct detection
correctly_detected_idx = closest_idx(dist_samples < tolerance_samples);

% True Positives: Number of reference QRSs correctly detected by test QRS
TP = length(unique(correctly_detected_idx));

% False Negatives: Number of reference QRSs that were not detected
FN = length(ref_qrs) - TP;

% False Positives: Number of detections that were wrong (no matching reference QRS)
FP = length(test_qrs) - TP;

% Sensitivity (aka True Positive Rate, recall, probability of correct detection)
SE  = TP/(TP+FN);

% Prositive predictive value (aka PPV, precision)
PPV = TP/(TP+FP);

% F1: Harmonic mean of SE and PPV
F1 = 2 * SE * PPV/(SE + PPV);

% Handle 0/0
if isnan(F1)
    F1 = 0;
end

% Save quality measures in a struct
sqi = struct('F1', F1, 'SE', SE, 'PPV', PPV, 'TP', TP, 'FP', FP, 'FN', FN);

%% Plot
if should_plot
    figure;

    plot(tm, sig); hold on; grid on;
    plot(tm(ref_qrs), sig(ref_qrs,1), 'bx');

    if ~isnan(test_qrs)
        plot(tm(test_qrs), sig(test_qrs,1), 'ro');
    end

    legend('sig', 'reference', qrs_detector);
end
