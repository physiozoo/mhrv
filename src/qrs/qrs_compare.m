function [sqi, tm, sig, ref_qrs, test_qrs] = qrs_compare( rec_name, varargin )

%% === Input

% Defaults
DEFAULT_SHOULD_PLOT = false;
DEFAULT_THRESH = 0.15; % 150 ms
DEFAULT_ANN_EXT = 'atr';
DEFAULT_ECG_COL = [];
DEFAULT_QRS_DETECTOR = 'gqrs';

% Define input
p = inputParser;
p.addRequired('rec_name', @isstr);
p.addParameter('should_plot', DEFAULT_SHOULD_PLOT, @islogical);
p.addParameter('bsqi_thresh', DEFAULT_THRESH, @isnumeric);
p.addParameter('annotation_ext', DEFAULT_ANN_EXT, @isstr);
p.addParameter('ecg_col', DEFAULT_ECG_COL, @isnumeric);
p.addParameter('qrs_detector', DEFAULT_QRS_DETECTOR, @isstr);

% Get input
p.parse(rec_name, varargin{:});
should_plot = p.Results.should_plot;
bsqi_thresh = p.Results.bsqi_thresh;
annotation_ext = p.Results.annotation_ext;
ecg_col = p.Results.ecg_col;
qrs_detector = p.Results.qrs_detector;

if strcmp(qrs_detector,'gqrs') || strcmp(qrs_detector,'rqrs')
    qrs_detector = eval(sprintf('@(rec, ecg_col) %s(rec, ''ecg_col'', ecg_col)', qrs_detector));
else
    error('Unknown qrs detector: %s. Must be: ''gqrs'' or ''rqrs''.', qrs_detector);
end

%% === Find ECG signal index if it wasn't specified
if (isempty(ecg_col))
    ecg_col = get_signal_channel(rec_name);
    if (isempty(ecg_col)); error('can''t find ECG signal in record'); end;
end

%% === Processing

% Read the signal
[tm, sig, ~] = rdsamp(rec_name, ecg_col);
Fs = 1/(tm(2)-tm(1));  % Fs returned from rdsamp is unreliable

% Get the reference QRS annotations
ref_qrs = rdann(rec_name, annotation_ext);

% Calculate QRS locations
test_qrs = qrs_detector(rec_name, ecg_col);

% Calculate SQI indices
[ F1, Se, PPV, TP, FP, FN ] = bsqi(ref_qrs, test_qrs, bsqi_thresh, Fs);

% Save SQI measures in a struct
sqi = struct('recName', rec_name, 'F1', F1, 'Se', Se, 'PPV', PPV, 'TP', TP, 'FP', FP, 'FN', FN);

% Plot both if necessary
if ~should_plot; return; end;
figure;
plot(tm, sig); hold on; grid on;
plot(tm(ref_qrs), sig(ref_qrs,1), 'bx');
if (~isnan(test_qrs)); plot(tm(test_qrs), sig(test_qrs,1), 'ro'); end;
legend('sig', 'reference', 'gqrs');