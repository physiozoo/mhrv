function [ hrv_tables, stats_tables ] = rhrv_batch( rec_dir, varargin )
%RHRV_BATCH Summary of this function goes here
%   Detailed explanation goes here

%% Handle input

% Defaults
DEFAULT_REC_TYPES = {'*'};
DEFAULT_REC_NAMES = {'ALL'};
DEFAULT_RHRV_PARAMS = 'human';
DEFAULT_MIN_NN = 300;
DEFAULT_OUTPUT_FOLDER = '.';
DEFAULT_OUTPUT_FILENAME = [];

% Define input
p = inputParser;
p.addRequired('rec_dir', @(x) exist(x,'dir'));
p.addParameter('rec_types', DEFAULT_REC_TYPES, @iscellstr);
p.addParameter('rec_names', DEFAULT_REC_NAMES, @iscellstr);
p.addParameter('rhrv_params', DEFAULT_RHRV_PARAMS, @ischar);
p.addParameter('min_nn', DEFAULT_MIN_NN, @isscalar);
p.addParameter('output_dir', DEFAULT_OUTPUT_FOLDER, @isstr);
p.addParameter('output_filename', DEFAULT_OUTPUT_FILENAME, @isstr);
p.addParameter('writexls', false, @islogical);

% Get input
p.parse(rec_dir, varargin{:});
rec_types = p.Results.rec_types;
rec_names = p.Results.rec_names;
rhrv_params = p.Results.rhrv_params;
min_nn = p.Results.min_nn;
output_dir = p.Results.output_dir;
output_filename = p.Results.output_filename;
writexls = p.Results.writexls;

if ~strcmp(rec_dir(end),filesep)
    rec_dir = [rec_dir filesep];
end
n_rec_types = length(rec_types);
if length(rec_names) ~= n_rec_types
    error('Different number of record types and names provided.');
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
hrv_tables = cell(1, length(rec_types));
stats_tables = cell(1, length(rec_types));

% Loop over record types and caculate a metrics table
for rec_type_idx = 1:n_rec_types
    % Get files matching the currect record type's pattern
    files = dir([rec_dir sprintf('%s.dat', rec_types{rec_type_idx})])';
    nfiles = length(files);

    if nfiles == 0
        warning('no record files found in %s for pattern %s', rec_dir, rec_types{rec_type_idx});
        continue;
    end
    
    % Loop over each file in the record type and calculate it's metrics
    rec_type_table = table;
    for file_idx = 1:nfiles
        % Extract the rec_name from the filename
        file = files(file_idx);
        [path, name, ~] = fileparts([rec_dir file.name]);
        rec_name = [path filesep name];
        
        % Analyze the record
        fprintf('-> Analyzing record %s\n', rec_name);
        curr_hrv = rhrv(rec_name, 'params', rhrv_params, 'plot', false);
        
        % Make sure we have a minimal amount of data in this file.
        if curr_hrv.NN < min_nn
            warning('Less than %d NN intervals detected, skipping...', min_nn);
            continue;
        end
        
        % Set name of row to be the record name (without full path)
        curr_hrv.Properties.RowNames{1} = name;
        
        % Append current file's metrics to the metrics for the rec type
        rec_type_table = [rec_type_table; curr_hrv];
    end
    
    % Save rec_type tables
    hrv_tables{rec_type_idx} = rec_type_table;
    stats_tables{rec_type_idx} = table_stats(rec_type_table);
end

% Display tables
for rec_type_idx = 1:n_rec_types
    if isempty(hrv_tables{rec_type_idx})
        continue;
    end
    fprintf(['\n' rec_names{rec_type_idx} ' metrics:\n']);
    disp([hrv_tables{rec_type_idx}; stats_tables{rec_type_idx}]);
end

%% Generate output
if ~writexls
    return;
end

% Disable warnings about adding non-existing excel sheets
orig_warnings = warning;
warning('off', 'MATLAB:xlswrite:AddSheet');

% Delete output file if it exists
if exist(output_filename, 'file')
    delete(output_filename);
end

summary_titles = {};
for rec_type_idx = 1:n_rec_types
    curr_hrv = hrv_tables{rec_type_idx};
    curr_stats = stats_tables{rec_type_idx};

    if isempty(curr_hrv)
        continue;
    end

    % Write results table (HRV and Stats combined)
    sheetname = strrep(rec_names{rec_type_idx}, ' ', '_');
    writetable([curr_hrv; curr_stats], output_filename,...
                'WriteVariableNames', true, 'WriteRowNames', true, 'Sheet', sheetname);

    % Create a summary table (Stats as columns, HRV metrics as rows)
    summary_table = table_transpose(curr_stats);

    % Column number in spreadsheet
    col_num = (rec_type_idx-1) * (size(summary_table,2) + 1) + 1;
    
    % Save the current rec type into a cell array at the column we'll write the table to
    summary_titles{col_num} = rec_names{rec_type_idx};

    % Write summary table to file
    write_rows = false; if rec_type_idx == 1; write_rows = true; end
    writetable(summary_table, output_filename,...
        'WriteVariableNames', true, 'WriteRowNames', false, 'Sheet', 'Summary',...
        'Range', [excel_column(col_num+1) '2']);
    
end

if isempty(summary_titles)
    return;
end

% Write the titles above the summary tables
writetable(cell2table(summary_titles), output_filename,...
        'WriteVariableNames', false, 'WriteRowNames', false, 'Sheet', 'Summary',...
        'Range', 'B1');

% Write the HRV metrics names to the summary table
writetable(cell2table(summary_table.Properties.RowNames), output_filename,...
        'WriteVariableNames', false, 'WriteRowNames', false, 'Sheet', 'Summary',...
        'Range', 'A3');

% Restore warning state
warning(orig_warnings);
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
