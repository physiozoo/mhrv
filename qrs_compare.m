function [sqi] = qrs_compare( recName, varargin )

%% === Input

% Defaults
DEFAULT_N = [];
DEFAULT_SHOULD_PLOT = false;
DEFAULT_THRESH = 0.15; % 150 ms
DEFAULT_ANN_EXT = 'atr';
DEFAULT_ECG_COL = 1;

% Define input
p = inputParser;
p.addRequired('recName', @isstr);
p.addOptional('N', DEFAULT_N, @isnumeric);
p.addParameter('should_plot', DEFAULT_SHOULD_PLOT, @islogical);
p.addParameter('bsqi_thresh', DEFAULT_THRESH, @isnumeric);
p.addParameter('annotation_ext', DEFAULT_ANN_EXT, @isstr);
p.addParameter('ecg_col', DEFAULT_ECG_COL, @isnumeric);

% Get input
p.parse(recName, varargin{:});
N = p.Results.N;
should_plot = p.Results.should_plot;
bsqi_thresh = p.Results.bsqi_thresh;
annotation_ext = p.Results.annotation_ext;
ecg_col = p.Results.ecg_col;

%% === Processing

% Read the signal
[tm, sig, ~] = rdsamp(recName, ecg_col, N);
Fs = 1/(tm(2)-tm(1));  % Fs returned from rdsamp is unreliable

% Get the reference QRS annotations
ref_qrs = rdann(recName, annotation_ext, [], N);

% Calculate QRS locations
gqrs(recName, N, 0, ecg_col, [], 'qrs_tmp');
try % In case of some very bad data, gqrs might fail to find anything.
    test_qrs = rdann(recName, 'qrs_tmp', [], N);
catch
    warning('%s: Failed to read gqrs results', recName);
    test_qrs = NaN;
end
delete([recName '.qrs_tmp']); % remove intermediary file

% Calculate SQI indices
[ F1, Se, PPV, TP, FP, FN ] = bsqi(ref_qrs, test_qrs, bsqi_thresh, Fs);

% Save SQI measures in a struct
sqi = struct('recName', recName, 'F1', F1, 'Se', Se, 'PPV', PPV, 'TP', TP, 'FP', FP, 'FN', FN);

% Plot both if necessary
if ~should_plot; return; end;
figure;
plot(tm, sig); hold on; grid on;
plot(tm(ref_qrs), sig(ref_qrs,1), 'bx');
if (~isnan(test_qrs)); plot(tm(test_qrs), sig(test_qrs,1), 'ro'); end;
legend('sig', 'reference', 'gqrs');