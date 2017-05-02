function [ all_tables ] = rhrv_batch( rec_dir, varargin )
%RHRV_BATCH Summary of this function goes here
%   Detailed explanation goes here

%% Handle input

% Defaults
DEFAULT_REC_TYPES = {'*'};
DEFAULT_REC_NAMES = {'ALL'};
DEFAULT_OUTPUT_FOLDER = '.';
DEFAULT_OUTPUT_FILENAME = [];

% Define input
p = inputParser;
p.addRequired('rec_dir', @(x) exist(x,'dir'));
p.addParameter('rec_types', DEFAULT_REC_TYPES, @iscellstr);
p.addParameter('rec_names', DEFAULT_REC_NAMES, @iscellstr);
p.addParameter('output_dir', '.', @isstr);
p.addParameter('output_filename', '', @isstr);
p.addParameter('writexls', true, @islogical);

% Get input
p.parse(rec_dir, varargin{:});
rec_types = p.Results.rec_types;
rec_names = p.Results.rec_names;
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
all_tables = cell(1, length(rec_types));

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
    curr_table = table;
    for file_idx = 1:nfiles
        % Extract the rec_name from the filename
        file = files(file_idx);
        [path, name, ~] = fileparts([rec_dir file.name]);
        rec_name = [path filesep name];
        
        % Analyze the record
        fprintf('-> Analyzing record %s\n', rec_name);
        curr_hrv = rhrv(rec_name, 'params', 'canine', 'plot', false);
        
        % Make sure we have a minimal amount of data in this file.
        if curr_hrv.NN < 300
            warning('Less than 300 NN intervals detected, skipping...');
            continue;
        end
        
        % Set name of row to be the record name (without full path)
        curr_hrv.Properties.RowNames{1} = name;
        
        % Append current file's metrics to the metrics for the rec type
        curr_table = [curr_table; curr_hrv];
    end

    % Get row and column names for the entire rec_type table
    row_names = curr_table.Properties.RowNames;
    var_names = curr_table.Properties.VariableNames;
    
    % Calculate Mean & SE of each column (metric)
    mean_values = num2cell( mean(curr_table{:, :}) );
    se_values = num2cell( std(curr_table{:, :})./ sqrt(size(curr_table,1)) );
    
    % Append Mean & SE rows to the current table
    curr_table = [curr_table;
                  table(mean_values{:}, 'VariableNames', var_names);
                  table(se_values{:},   'VariableNames', var_names)];
    
    % Add row names for the new rows
    curr_table.Properties.RowNames = [row_names; 'Mean'; 'SE'];
    
    % Save rec_type table
    all_tables{rec_type_idx} = curr_table;
end

% Display tables
for rec_type_idx = 1:n_rec_types
    if isempty(all_tables{rec_type_idx})
        continue;
    end
    fprintf(['\n' rec_names{rec_type_idx} ' metrics:\n']);
    disp(all_tables{rec_type_idx});
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

summ_titles = {};
for rec_type_idx = 1:n_rec_types
    curr_table = all_tables{rec_type_idx};
    if isempty(curr_table)
        continue;
    end

    % Write results table
    sheetname = strrep(rec_names{rec_type_idx}, ' ', '_');
    writetable(curr_table, output_filename,...
                'WriteVariableNames', true, 'WriteRowNames', true, 'Sheet', sheetname);

    % Create a summary table (Mean and SE as columns, HRV metrics as rows)
    summ_table = table(curr_table{end-1,:}', curr_table{end,:}',...
                'VariableNames', curr_table.Properties.RowNames(end-1:end),...
                'RowNames', curr_table.Properties.VariableNames);

    % Column number in spreadsheet
    col_num = (rec_type_idx-1) * (size(summ_table,2) + 1) + 1;
    
    % Save the current rec type into a cell array at the column we'll write the table to
    summ_titles{col_num} = rec_names{rec_type_idx};

    % Write summary table to file
    write_rows = false; if rec_type_idx == 1; write_rows = true; end
    writetable(summ_table, output_filename,...
        'WriteVariableNames', true, 'WriteRowNames', false, 'Sheet', 'Summary',...
        'Range', [excel_column(col_num+1) '2']);
    
end

if isempty(summ_titles)
    return;
end

% Write the titles above the summary tables
writetable(cell2table(summ_titles), output_filename,...
        'WriteVariableNames', false, 'WriteRowNames', false, 'Sheet', 'Summary',...
        'Range', 'B1');

% Write the HRV metrics names to the summary table
writetable(cell2table(summ_table.Properties.RowNames), output_filename,...
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
