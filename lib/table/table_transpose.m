function [ transposed_table ] = table_transpose( input_table )
%TABLE_TRANSPOSE Transposes a table
%   Exchanges between a table's rows and columns, while preserving their names.
%
%   input_table: Table to transpose.
%   transposed_table: Transposed table.
%

% All table data as a matrix
data = input_table{:, :};

% Get variable (column) and row names of the input table
var_names = input_table.Properties.VariableNames;
row_names = input_table.Properties.RowNames;

% Create transposed table - use transposed data, set variable names as rows and vice-versa
transposed_table = array2table(data', 'VariableNames', row_names', 'RowNames', var_names');

end
