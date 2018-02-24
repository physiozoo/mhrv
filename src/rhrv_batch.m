function [ batch_data ] = rhrv_batch( rec_dir, varargin )
%RHRV_BATCH Performs batch processing of multiple records with rhrv
%   This function analyzes multiple physionet records with rhrv and outputs tables containting the
%   results. The records to analyze can be subdivided into record types, in which case output
%   tables will be generated for each record type.
%   Optionally, an Excel file can be generated containing the results of the analysis.
%
%   Inputs:
%       - rec_dir: Directory to scan for input files.
%       - varargin: Optional key-value parameter pairs.
%           - ann_ext: Specify an annotation file extention to use instead of loading the record
%             itself (.dat file). If provided, RR intervals will be loaded from the annotation file
%             instead of from the ECG.  Default: empty (don't use annotation).
%           - rec_types: A cell array containing the names of the type of record to analyze.
%           - rec_filenames: A cell array with identical length as 'rec_names', containing
%             patterns to match against the files in 'rec_dir' for each 'rec_type'.
%           - rec_transforms: A cell array of transform functions to apply to each file in each
%             record (one transform for each rec_type).
%           - min_nn: Set a minumum number of NN intervals so that windows with less will be
%             discarded. Default is 0 (don't discard anything).
%           - rhrv_params: Parameters cell array to pass into rhrv when processing each record.
%           - skip_plot_data: Whether to skip saving the plot data for each record. This can reduce
%             memory consumption significantly for large batches. Default: false.
%           - writexls: true/false whether to write the output to an Excel file.
%           - output_dir: Directory to write output file to.
%           - output_filename: Desired name of the output file.
%
%   Output:
%        A structure, batch_data, containing the following fields"
%           - rec_types: A cell of strings of the names of the record types that were analyzed.
%           - rec_transforms: A cell array of the RR transformation functis used on each record
%             type.
%           - rhrv_window_minutes: Number of minutes in each analysis windows that each record was
%             split into.
%           - rhrv_params: A cell array containing the value of the `params` argument passed to rhrv
%             for the analysis (see rhrv documentation).
%           - hrv_tables: A map from each value in 'rec_types' to the table of HRV values for that type.
%           - stats_tables: A map with keys as above, whose values are summary tables for each type.
%           - plot_datas: A map with keys as above, whose values are also maps, mapping from an
%             individual record filename to the matching plot data object (which can be used for
%             generating plots).
%

%% Handle input

% Defaults
DEFAULT_ANN_EXT = '';
DEFAULT_REC_TYPES = {'ALL'};
DEFAULT_REC_FILENAMES = {'*'};
DEFAULT_RHRV_PARAMS = 'defaults';
DEFAULT_WINDOW_MINUTES = Inf;
DEFAULT_MIN_NN = 0;
DEFAULT_OUTPUT_FOLDER = '.';
DEFAULT_OUTPUT_FILENAME = [];

% Define input
p = inputParser;
p.addRequired('rec_dir', @(x) exist(x,'dir'));
p.addParameter('ann_ext', DEFAULT_ANN_EXT, @(x) ischar(x));
p.addParameter('rec_types', DEFAULT_REC_TYPES, @iscellstr);
p.addParameter('rec_filenames', DEFAULT_REC_FILENAMES, @iscellstr);
p.addParameter('rec_transforms', {}, @iscell);
p.addParameter('rhrv_params', DEFAULT_RHRV_PARAMS, @(x) ischar(x)||iscell(x));
p.addParameter('window_minutes', DEFAULT_WINDOW_MINUTES, @(x) isnumeric(x) && numel(x) < 2 && x > 0);
p.addParameter('min_nn', DEFAULT_MIN_NN, @isscalar);
p.addParameter('skip_plot_data', false, @islogical);
p.addParameter('output_dir', DEFAULT_OUTPUT_FOLDER, @isstr);
p.addParameter('output_filename', DEFAULT_OUTPUT_FILENAME, @isstr);
p.addParameter('writexls', false, @islogical);

% Get input
p.parse(rec_dir, varargin{:});
ann_ext = p.Results.ann_ext;
rec_types = p.Results.rec_types;
rec_filenames = p.Results.rec_filenames;
rec_transforms = p.Results.rec_transforms;
rhrv_params = p.Results.rhrv_params;
window_minutes = p.Results.window_minutes;
min_nn = p.Results.min_nn;
output_dir = p.Results.output_dir;
output_filename = p.Results.output_filename;
writexls = p.Results.writexls;
skip_plot_data = p.Results.skip_plot_data;

if ~strcmp(rec_dir(end),filesep)
    rec_dir = [rec_dir filesep];
end

n_rec_types = length(rec_types);
if length(rec_filenames) ~= n_rec_types
    error('Different number of record types and filenames provided.');
end

if isempty(rec_transforms)
    rec_transforms = cell(1, n_rec_types);
elseif length(rec_transforms) ~= n_rec_types
    error('Different number of record types and transforms provided.');
elseif ~all(cellfun(@(x)isempty(x) || isa(x,'function_handle'), rec_transforms))
    error('Record type transforms cell array must only contain function handles.');
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

if isempty(output_filename)
    [~, output_dirname, ~] = file_parts(output_dir);
    output_filename = ['rhrv_batch_' output_dirname];
end
output_filename = [output_dir filesep output_filename '.xlsx'];

%% Analyze data

% Allocate cell array the will contain all the tables (one for each record type).
hrv_tables = cell(1,n_rec_types);
stats_tables = cell(1,n_rec_types);
plot_datas = cell(1,n_rec_types);

% Loop over record types and caculate a metrics table
fprintf('-> Starting batch processing...\n');
t0 = tic;
for rec_type_idx = 1:n_rec_types
    rec_type_filenames = rec_filenames{rec_type_idx};
    rec_type_transform = rec_transforms{rec_type_idx};

    % Get files matching the currect record type's pattern
    files = dir([rec_dir sprintf('%s.hea', rec_type_filenames)])';
    nfiles = length(files);

    if nfiles == 0
        warning('no record files found in %s for pattern %s', rec_dir, rec_type_filenames);
        continue;
    end

    % Loop over each file in the record type and calculate it's metrics
    rec_type_tables = cell(nfiles, 1);
    rec_type_plot_datas = cell(nfiles, 1);
    parfor file_idx = 1:nfiles
        % Extract the rec_name from the filename
        file = files(file_idx);
        [path, name, ~] = file_parts([file.folder filesep file.name]);
        rec_name = [path filesep name];

        % Analyze the record
        fprintf('-> Analyzing record %s\n', rec_name);
        try
            [curr_hrv, ~, curr_plot_datas] = rhrv(rec_name, 'window_minutes', window_minutes,...
                'ann_ext', ann_ext, 'params', rhrv_params, 'transform_fn', rec_type_transform, 'plot', false);
        catch e
            warning('Error analyzing record %s: %s\nSkipping...', rec_name, e.message);
            continue;
        end

        % Make sure we have a minimal amount of data in this file.
        if curr_hrv.NN < min_nn
            warning('Less than %d NN intervals detected, skipping...', min_nn);
            continue;
        end

        % Handle naming of rows to prevent duplicate names from different files
        % The number of rows depends on the lenghth of the data and the value of 'window_minutes'
        row_names = curr_hrv.Properties.RowNames;
        if length(row_names) == 1
            % If there's only one row, set name of row to be the record name (without full path)
            row_names{1} = name;
        else
            row_names = cellfun(@(row_name)sprintf('%s_%s', name, row_name), row_names, 'UniformOutput', false);
        end
        curr_hrv.Properties.RowNames = row_names;

        % Delete plot_data if it's not to be saved
        if skip_plot_data
            curr_plot_datas = {};
        end

        % Append current file's metrics to the metrics & plot data for the rec type
        rec_type_tables{file_idx} = curr_hrv;
        rec_type_plot_datas{file_idx} = curr_plot_datas;
    end

    % Concatenate all tables to one
    rec_type_table = vertcat(rec_type_tables{:});
    rec_type_plot_datas = vertcat(rec_type_plot_datas{:});

    % Save rec_type tables
    hrv_tables{rec_type_idx} = rec_type_table;
    stats_tables{rec_type_idx} = table_stats(rec_type_table);
    plot_datas{rec_type_idx} = rec_type_plot_datas;
end
fprintf('-> Batch processing complete (%.3f(s))\n', toc(t0));

%% Convert output to maps

% Convert from cell array of tables to a map, from the rec type to the matching table.
hrv_tables = containers.Map(rec_types, hrv_tables);
stats_tables = containers.Map(rec_types, stats_tables);

% Make plot_datas a map from rec_type to a map from rec filename to the plot data for that file
plot_datas = containers.Map(rec_types, plot_datas);
for rec_type_idx = 1:n_rec_types
    rec_type = rec_types{rec_type_idx};

    % Get all filenames and corresponding plot datas for the current record type
    rec_type_filenames = hrv_tables(rec_type).Properties.RowNames;
    rec_type_plot_datas = plot_datas(rec_type);

    % Map from each filename to the plot data for it
    if ~isempty(rec_type_plot_datas)
        % Remove any empty plot datas (from skipped files)
        nonempty_idx = cellfun(@(x) ~isempty(x), rec_type_plot_datas);
        rec_type_plot_datas = rec_type_plot_datas(nonempty_idx);

        plot_datas(rec_type) = containers.Map(rec_type_filenames, rec_type_plot_datas);
    end
end

%% Display tables
for rec_type_idx = 1:n_rec_types
    rec_type = rec_types{rec_type_idx};
    if isempty(hrv_tables(rec_type))
        continue;
    end
    fprintf(['\n-> ' rec_type ' metrics:\n']);
    disp([hrv_tables(rec_type); stats_tables(rec_type)]);
end

%% Generate output structure

batch_data = struct;
batch_data.rec_types = rec_types;
batch_data.rec_transforms = rec_transforms;
batch_data.rhrv_window_minutes = window_minutes;
batch_data.rhrv_params = rhrv_params;
batch_data.hrv_tables = hrv_tables;
batch_data.stats_tables = stats_tables;
batch_data.plot_datas = plot_datas;

%% Generate output file
if ~writexls
    return;
end

% Disable warnings about adding non-existing Excel sheets
orig_warnings = warning;
warning('off', 'MATLAB:xlswrite:AddSheet');

% Delete output file if it exists
if exist(output_filename, 'file')
    delete(output_filename);
end

fprintf('\n-> Writing output file "%s"...\n', output_filename);
t0 = tic;

summary_titles = {};
for rec_type_idx = 1:n_rec_types
    rec_type = rec_types{rec_type_idx};
    curr_hrv = hrv_tables(rec_type);
    curr_stats = stats_tables(rec_type);

    if isempty(curr_hrv)
        continue;
    end

    % Write results table (HRV and Stats combined)
    sheetname = strrep(rec_types{rec_type_idx}, ' ', '_');
    writetable([curr_hrv; curr_stats], output_filename,...
                'WriteVariableNames', true, 'WriteRowNames', true, 'Sheet', sheetname);

    % Create a summary table (Stats as columns, HRV metrics as rows)
    summary_table = table_transpose(curr_stats);

    % Column number in spreadsheet
    col_num = (rec_type_idx-1) * (size(summary_table,2) + 1) + 1;

    % Save the current rec type into a cell array at the column we'll write the table to
    summary_titles{col_num} = rec_types{rec_type_idx};

    % Write summary table to file
    writetable(summary_table, output_filename,...
        'WriteVariableNames', true, 'WriteRowNames', false, 'Sheet', 'Summary',...
        'Range', [excel_column(col_num+1) '2']);
end

if ~isempty(summary_titles)
    % Write the titles above the summary tables
    writetable(cell2table(summary_titles), output_filename,...
        'WriteVariableNames', false, 'WriteRowNames', false, 'Sheet', 'Summary',...
        'Range', 'B1');

    % Write the HRV metrics names to the summary table
    writetable(cell2table(summary_table.Properties.RowNames), output_filename,...
        'WriteVariableNames', false, 'WriteRowNames', false, 'Sheet', 'Summary',...
        'Range', 'A3');
end

% Restore warning state
warning(orig_warnings);

fprintf('-> Done. (%.3f(s))\n', toc(t0));
end

%% Helper functions
function col_letter = excel_column(matlab_col)
    dividend = matlab_col;
    col_letter = '';

    while (dividend > 0)
        modulo = mod(dividend-1, 26);
        col_letter = sprintf('%c%s', 65+modulo, col_letter);
        dividend = floor((dividend - modulo)/26);
    end
end
