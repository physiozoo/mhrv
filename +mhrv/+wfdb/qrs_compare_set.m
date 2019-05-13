function [ sqis, stats ] = qrs_compare_set( set_dir, ann_ext, varargin )
%Compares reference QRS detections to test detections on a set of wfdb records.
%
%:param set_dir: directory path containing the wfdb files and annotations
%:param ann_ext: file extension of the annotation files.
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - any parameter supported by qrs_compare() can be passed to this function.
%   - plot: true/false whether to generate a plot. Defaults to true if no
%     output arguments were specified.
%
%:returns:
%   - sqis: A table containing quality indices for each of the input files.
%   - stats: A table containing the Mean and Gross values for the quality indices over all files.
%

import mhrv.wfdb.*;
import mhrv.defaults.*;

%% Input

% Define input
p = inputParser;
p.addRequired('set_dir', @(x) exist(x, 'dir'));
p.addRequired('ann_ext', @(x) ischar(x) && ~isempty(x));
p.addParameter('params', 'defaults', @ischar);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.KeepUnmatched = true;
p.parse(set_dir, ann_ext, varargin{:});
params = p.Results.params;
should_plot = p.Results.plot;

%% Process files

% Measure time
t1 = tic;

% Get files in dir that have an annotation with the desired ext
files = dir([set_dir filesep '*.' ann_ext]);
fprintf('** Found %d ''%s'' files in %s, processing...\n', length(files), ann_ext, set_dir);

spmd
    mhrv_init;
    mhrv_load_defaults(params);
end

% Process files
N = length(files);
N_error = 0;
sqis = table;
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
        fprintf('>> WARNING - No ECG data found in record %s. Skipping...\n', basename);
        N_error = N_error + 1;
        continue;
    end
    
    % Calculate SQI indices
    params = p.Unmatched;
    params.ann_ext = ann_ext;
    sqi = qrs_compare(recName, params);

    % Convert to table with file name as table row name
    sqi = struct2table(sqi);
    sqi.Properties.RowNames = {basename};

    % Add to output table
    sqis = [sqis; sqi];

    % Print elapsed time
    elapsed_sec = toc(t2);
    fprintf('>> %s [elapsed = %6.3fs]\n', basename, elapsed_sec);
end
fprintf('** Done processing, total time: %.3fs\n', toc(t1));

%% Calculate mean & gross values for metrics
N_no_error = N - N_error;
mean.SE  = 100 * sum(sqis.SE) / N_no_error;
mean.PPV = 100 * sum(sqis.PPV)/ N_no_error;
mean.F1 =  100 * sum(sqis.F1) / N_no_error;

TP = sum(sqis.TP);
FP = sum(sqis.FP);
FN = sum(sqis.FN);
gross.SE  = 100 * TP/(TP+FN);
gross.PPV = 100 * TP/(FP+TP);
gross.F1 =  2 * gross.SE * gross.PPV / (gross.SE + gross.PPV);

% Add to table
stats = [
    struct2table(mean, 'RowNames', {'Mean'});
    struct2table(gross, 'RowNames', {'Gross'});
];

% Print Results
fprintf('\n** Results:\n'); disp(sqis);
fprintf('\n** Summary:\n'); disp(stats);

%% Plot
if should_plot
    figure;
    bar([mean.SE, mean.PPV, mean.F1; gross.SE, gross.PPV, gross.F1]);
    grid on;

    ylim([90, 100]);
    set(gca, 'XTickLabel', {'Mean', 'Gross'}, 'XTick', 1:2);
    set(gca, 'YTick', [90:1:98, 98.5:0.5:100]);
    xlabel('Measures'); ylabel('% Value');
    legend('SE', 'PPV', 'F1');
end
