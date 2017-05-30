function [ hrv_tables, stats_tables, plot_datas ] = rhrv_batch( rec_dir, varargin )
%RHRV_BATCH Performs batch processing of multiple records with rhrv
%   This function analyzes multiple physionet in  with rhrv and outputs table containting the
%   results. The records to analyze can be subdivided into record types, in which case output
%   tables will be generated for each record type.
%   Optionally, an Excel file can be generated containing the results of the analysis.
%
%   Inputs:
%       - rec_dir: Directory to scan for input files.
%       - varargin: Optional key-value parameter pairs.
%           - rec_types: A cell array containing the names of the type of record to analyze.
%           - rec_filenames: A cell array with identical length as 'rec_names', containing
%             patterns to match against the files in 'rec_dir' for each 'rec_type'.
%           - rec_transforms: A cell array of transform functions to apply to each file in each
%             record (one transform for each rec_type).
%           - rhrv_params: Parameters cell array to pass into rhrv when processing each record.
%           - writexls: true/false whether to write the output to an Excel file.
%           - output_dir: Directory to write output file to.
%           - output_filename: Desired name of the output file.
%
%   Outputs:
%       - hrv_tables: A map from each value in 'rec_types' to the table of HRV values for that type.
%       - stats_tables: A with keys as above, whose values are summary tables for each type.
%       - plot_datas: A map with keys as above, whose values are also maps, mapping from an
%         individual record filename to the matching plot data object (which can be used for
%         generating plots).
%

%% Handle input

% Defaults
DEFAULT_REC_TYPES = {'ALL'};
DEFAULT_REC_FILENAMES = {'*'};
DEFAULT_RHRV_PARAMS = 'human';
DEFAULT_MIN_NN = 0;
DEFAULT_OUTPUT_FOLDER = '.';
DEFAULT_OUTPUT_FILENAME = [];

% Define input
p = inputParser;
p.addRequired('rec_dir', @(x) exist(x,'dir'));
p.addParameter('rec_types', DEFAULT_REC_TYPES, @iscellstr);
p.addParameter('rec_filenames', DEFAULT_REC_FILENAMES, @iscellstr);
p.addParameter('rec_transforms', {}, @iscell);
p.addParameter('rhrv_params', DEFAULT_RHRV_PARAMS, @(x) ischar(x)||iscell(x));
p.addParameter('min_nn', DEFAULT_MIN_NN, @isscalar);
p.addParameter('output_dir', DEFAULT_OUTPUT_FOLDER, @isstr);
p.addParameter('output_filename', DEFAULT_OUTPUT_FILENAME, @isstr);
p.addParameter('writexls', false, @islogical);

% Get input
p.parse(rec_dir, varargin{:});
rec_types = p.Results.rec_types;
rec_filenames = p.Results.rec_filenames;
rec_transforms = p.Results.rec_transforms;
rhrv_params = p.Results.rhrv_params;
min_nn = p.Results.min_nn;
output_dir = p.Results.output_dir;
output_filename = p.Results.output_filename;
writexls = p.Results.writexls;
save_plot_data = nargout > 2;

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
    [~, output_dirname, ~] = fileparts(output_dir);
    output_filename = ['rhrv_batch_' output_dirname];
end
output_filename = [output_dir filesep output_filename '.xlsx'];

%% Analyze data

% Allocate cell array the will contain all the tables (one for ear record type).
hrv_tables = cell(1,n_rec_types);
stats_tables = cell(1,n_rec_types);
plot_datas = cell(1,n_rec_types);

% Loop over record types and caculate a metrics table
fprintf('-> Starting batch processing...\n');
t0 = tic;
parfor rec_type_idx = 1:n_rec_types
    rec_type_filenames = rec_filenames{rec_type_idx};
    rec_type_transform = rec_transforms{rec_type_idx};

    % Get files matching the currect record type's pattern
    files = dir([rec_dir sprintf('%s.dat', rec_type_filenames)])';
    nfiles = length(files);

    if nfiles == 0
        warning('no record files found in %s for pattern %s', rec_dir, rec_type_filenames);
        continue;
    end
    
    % Loop over each file in the record type and calculate it's metrics
    rec_type_table = table;
    rec_type_plot_datas = cell(nfiles, 1);
    for file_idx = 1:nfiles
        % Extract the rec_name from the filename
        file = files(file_idx);
        [path, name, ~] = fileparts([rec_dir file.name]);
        rec_name = [path filesep name];
        
        % Analyze the record
        fprintf('-> Analyzing record %s\n', rec_name);
        [curr_hrv, ~, curr_plot_data] = rhrv(rec_name,...
            'params', rhrv_params, 'transform_fn', rec_type_transform, 'plot', false);

        % Make sure we have a minimal amount of data in this file.
        if curr_hrv.NN < min_nn
            warning('Less than %d NN intervals detected, skipping...', min_nn);
            continue;
        end
        
        % Set name of row to be the record name (without full path)
        curr_hrv.Properties.RowNames{1} = name;
        
        % Append current file's metrics to the metrics & plot data for the rec type
        rec_type_table = [rec_type_table; curr_hrv];
        if save_plot_data
            rec_type_plot_datas{file_idx} = curr_plot_data{1}; % 1 is the window number (we're using only one)
        end
    end
    
    % Save rec_type tables
    hrv_tables{rec_type_idx} = rec_type_table;
    stats_tables{rec_type_idx} = table_stats(rec_type_table);
    plot_datas{rec_type_idx} = rec_type_plot_datas;
end
fprintf('-> Batch processing complete (%.3f[s])\n', toc(t0));

%% Convert output to maps

% Convert from cell array of tables to a map, from the rec type to the matching table.
hrv_tables = containers.Map(rec_types, hrv_tables);
stats_tables = containers.Map(rec_types, stats_tables);

% Make plot_datas a map from rec_type to a map from rec filename to the plot data for that file
plot_datas = containers.Map(rec_types, plot_datas);
for rec_type_idx = 1:n_rec_types
    rec_type = rec_types{rec_type_idx};
    rec_type_filenames = hrv_tables(rec_type).Properties.RowNames;

    % Remove empty plot_data cells (might be empty due to min_nn)
    rec_type_plot_datas = plot_datas(rec_type);
    rec_type_plot_datas = rec_type_plot_datas(~cellfun('isempty',rec_type_plot_datas));

    plot_datas(rec_type) = containers.Map(rec_type_filenames, rec_type_plot_datas);
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

fprintf('-> Done. (%.3f[s])\n', toc(t0));
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
