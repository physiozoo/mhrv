function [ stats_table ] = table_stats( input_table )
%TABLE_STATS Calcultes statistics of each variable (column) in a table.
%   Calculates Mean, Standard Error and Median values for each variable (column) in a table.
%
%   input_table: A table containing numeric data.
%   stats_table: A new table with the same variables as the input, but with a row for each of
%                the calculated statistics.

% All table data as a matrix
data = input_table{:, :};

% Get variable (column) names of the input table
var_names = input_table.Properties.VariableNames;

% Calculate stats of each column (metric)
mean_values = nanmean(data, 1);
se_values = nanstd(data, 0, 1) ./ sqrt(size(input_table, 1));
median_values = nanmedian(data, 1);

% Build stats table
stats_table = [
    array2table(  mean_values, 'VariableNames', var_names, 'RowNames', {'Mean'});
    array2table(    se_values, 'VariableNames', var_names, 'RowNames', {'SE'});
    array2table(median_values, 'VariableNames', var_names, 'RowNames', {'Median'});
];

% Copy over the rest of the metadata
stats_table.Properties.VariableDescriptions = input_table.Properties.VariableDescriptions;
stats_table.Properties.VariableUnits = input_table.Properties.VariableUnits;
stats_table.Properties.Description = ['Statistics of ' input_table.Properties.Description];

end
