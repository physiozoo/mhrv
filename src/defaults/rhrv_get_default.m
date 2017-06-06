function [ value, name, description, units ] = rhrv_get_default( param_name, default_value )
%RHRV_GET_DEFAULT Returns the default value configured for a parameter.
%   This function attemps to get the value of a parameter as configured by a user config file.
%   If it can't find a user-specified default for the parameter, it returns a given value.
%
%   Inputs:
%       - param_name: name of the parameter.
%       - default_value: Value to use if this parameter wasn't configured by user.
%
%   Outputs:
%       - value: The user-configured parameter value, if exists, otherwise returns the 'default_value'.
%       - name: The user-friendly/display name of the parameter.
%       - description: A description about the parameter.
%       - units: The units the parameter is specified in.
%

% Set default if not provided
if nargin < 2
    default_value = [];
end

% Set provided default value
value = default_value;
name = '';
description = '';
units = '';

% If no defaults were loaded, we don't have anything to do
global rhrv_default_values;
if isempty(rhrv_default_values)    
    return;
end

% Split the "path" to the field in the parameter struct
field_path = strsplit(param_name, '.');

try
    field_data = getfield(rhrv_default_values, field_path{:});
catch
    % Field doesn't exist so return the provided default.
    return;
end

% Check if this parameter is a struct with metadata (value, description, ect).
if isfield(field_data, 'value')
    value = field_data.value;
    if isfield(field_data, 'name');         name = field_data.name; end
    if isfield(field_data, 'description');  description = field_data.description; end
    if isfield(field_data, 'units');        units = field_data.units; end
else
    value = field_data;
end

% Convert simple cell arrays (e.g. {[1],[2]}) to regular vectors. The Yaml parser we're using
% creates cell arrays when parsing.
if iscell(value) && size(value,1) && ~iscellstr(value) && all(cellfun(@isscalar, value))
    value = cell2mat(value);
end
end
