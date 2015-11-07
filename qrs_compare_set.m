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

% Define input
p = inputParser;
p.addRequired('set_dir', @(dir) exist(dir, 'dir'));
p.addParameter('should_plot', DEFAULT_SHOULD_PLOT, @islogical);
p.addParameter('bsqi_thresh', DEFAULT_THRESH, @isnumeric);
p.addParameter('annotation_ext', DEFAULT_ANN_EXT, @isstr);

% Get input
p.parse(set_dir, varargin{:});
should_plot = p.Results.should_plot;
bsqi_thresh = p.Results.bsqi_thresh;
annotation_ext = p.Results.annotation_ext;

%% === Process files

% Measure time
t1 = tic;

% Get files in dir that have an annotation with the desired ext
files = dir([set_dir '*.' annotation_ext]);
fprintf('** Found %d ''%s'' files in %s, processing...\n', length(files), annotation_ext, set_dir);

% Pre-allocate struct array
sqis = repmat(struct('recName','','Se',0,'PPV',0,'F1',0,'TP',0,'FP',0,'FN',0), length(files), 1);

% Process files
parfor i = 1:length(files)
    file = files(i);
    t2 = tic;
    
    % remove extention from filename
    [~, basename, ~] = fileparts(file.name);
    
    % WFDB name of the record (e.g. mitdb/100)
    recName = [set_dir filesep basename];
    
    % Make sure the record contains an ECG signal
    ecg_channel = get_signal_channel(recName, 'ecg');
    if (isempty(ecg_channel))
        warning('%s Does not seem to caintain ECG data. Skipping...', file.name);
        continue;
    end
    
    % Calculate SQI indices
    sqis(i) = qrs_compare(recName, 'bsqi_thresh', bsqi_thresh, 'ecg_col', ecg_channel);
    
    % Print elapsed time
    elapsed_sec = toc(t2);
    fprintf('** >> %s, elapsed = %.3fs\n', file.name, elapsed_sec);
end
fprintf('** Done processing, total time: %.3fs\n', toc(t1));

%% === Calculate average Se, PPV, F1
mean_Se  = mean(cell2mat({sqis.Se}));
mean_PPV = mean(cell2mat({sqis.PPV}));
mean_F1 = mean(cell2mat({sqis.F1}));

% Print results
fprintf('** Mean:  Se=%.3f, PPV=%.3f, F1=%.3f\n', mean_Se, mean_PPV, mean_F1);

%% === Calculate Gross Se, PPV, F1
TP = sum(cell2mat({sqis.TP}));
FP = sum(cell2mat({sqis.FP}));
FN = sum(cell2mat({sqis.FN}));
gross_Se  = TP/(TP+FN);
gross_PPV = TP/(FP+TP);
gross_F1 = 2 * gross_Se * gross_PPV / (gross_Se + gross_PPV);

% Print results
fprintf('** Gross: Se=%.3f, PPV=%.3f, F1=%.3f\n', gross_Se, gross_PPV, gross_F1);

% Plots
if ~should_plot; return; end;
figure;
bar([mean_Se, mean_PPV, mean_F1; gross_Se, gross_PPV, gross_F1] .* 100); grid on;
legend('Se', 'PPV', 'F1');
ylim([70, 100]);
set(gca, 'XTickLabel', {'Mean', 'Gross'}, 'XTick', 1:2);
set(gca, 'YTick', [70, 80, 90:1:100]);
xlabel('Measures'); ylabel('% Value');