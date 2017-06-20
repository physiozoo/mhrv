function [ sqis ] = qrs_compare_set( set_dir, varargin )
%QRS_COMPARE_SET Compares annotation QRS to gqrs on a set of wfdb records
%   Inputs:
%       set_dir - directory path containing the wfdb files and annotations
%

%% === Input

% Defaults
DEFAULT_SHOULD_PLOT = false;
DEFAULT_THRESH = 0.15; % 150 ms
DEFAULT_ANN_EXT = 'atr';
DEFAULT_QRS_DETECTOR = 'gqrs';

% Define input
p = inputParser;
p.addRequired('set_dir', @(dir) exist(dir, 'dir'));
p.addParameter('should_plot', DEFAULT_SHOULD_PLOT, @islogical);
p.addParameter('bsqi_thresh', DEFAULT_THRESH, @isnumeric);
p.addParameter('annotation_ext', DEFAULT_ANN_EXT, @isstr);
p.addParameter('qrs_detector', DEFAULT_QRS_DETECTOR, @isstr);

% Get input
p.parse(set_dir, varargin{:});
should_plot = p.Results.should_plot;
bsqi_thresh = p.Results.bsqi_thresh;
annotation_ext = p.Results.annotation_ext;
qrs_detector = p.Results.qrs_detector;

%% === Process files

% Measure time
t1 = tic;

% Get files in dir that have an annotation with the desired ext
files = dir([set_dir '*.' annotation_ext]);
fprintf('** Found %d ''%s'' files in %s, processing...\n', length(files), annotation_ext, set_dir);

% Pre-allocate struct array
sqis = repmat(struct('recName','','Se',0,'PPV',0,'F1',0,'TP',0,'FP',0,'FN',0), length(files), 1);

% Process files
N = length(files);
N_error = 0;
parfor i = 1:N
    file = files(i);
    t2 = tic;
    
    % remove extention from filename
    [~, basename, ~] = fileparts(file.name);
    
    % WFDB name of the record (e.g. mitdb/100)
    recName = [set_dir filesep basename];
    
    % Make sure the record contains an ECG signal
    ecg_channel = get_signal_channel(recName);
    if (isempty(ecg_channel))
        fprintf('** >> %10s: WARNING - No ECG data found. Skipping...\n', file.name);
        N_error = N_error + 1;
        continue;
    end
    
    % Calculate SQI indices
    sqis(i) = qrs_compare(recName, 'bsqi_thresh', bsqi_thresh, 'ecg_col', ecg_channel, 'qrs_detector', qrs_detector);
    
    % Print elapsed time
    elapsed_sec = toc(t2);
    fprintf('** >> %10s: Se = %5.3f, PPV = %5.3f, F1 = %5.3f [elapsed = %6.3fs]\n', file.name, sqis(i).Se, sqis(i).PPV, sqis(i).F1, elapsed_sec);
end
fprintf('** Done processing, total time: %.3fs\n', toc(t1));

%% === Calculate average Se, PPV, F1
N_no_error = N - N_error;
mean_Se  = 100 * sum(cell2mat({sqis.Se})) / N_no_error;
mean_PPV = 100 * sum(cell2mat({sqis.PPV}))/ N_no_error;
mean_F1 =  100 * sum(cell2mat({sqis.F1})) / N_no_error;

% Print results
fprintf('** Mean:  Se=%5.1f%%, PPV=%5.1f%%, F1=%5.1f%%\n', mean_Se, mean_PPV, mean_F1);

%% === Calculate Gross Se, PPV, F1
TP = sum(cell2mat({sqis.TP}));
FP = sum(cell2mat({sqis.FP}));
FN = sum(cell2mat({sqis.FN}));
gross_Se  = 100 * TP/(TP+FN);
gross_PPV = 100 * TP/(FP+TP);
gross_F1 =  2 * gross_Se * gross_PPV / (gross_Se + gross_PPV);

% Print results
fprintf('** Gross: Se=%5.1f%%, PPV=%5.1f%%, F1=%5.1f%%\n', gross_Se, gross_PPV, gross_F1);

% Plots
if ~should_plot; return; end;
figure;
bar([mean_Se, mean_PPV, mean_F1; gross_Se, gross_PPV, gross_F1] .* 100); grid on;
legend('Se', 'PPV', 'F1');
ylim([70, 100]);
set(gca, 'XTickLabel', {'Mean', 'Gross'}, 'XTick', 1:2);
set(gca, 'YTick', [70, 80, 90:1:100]);
xlabel('Measures'); ylabel('% Value');