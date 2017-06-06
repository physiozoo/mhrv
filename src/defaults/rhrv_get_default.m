function [ param_value ] = rhrv_get_default( param_name, default_value )
%RHRV_GET_DEFAULT Returns the default value configured for a parameter.
%   This function attemps to get the value of a parameter as configured by a user config file.
%   If it can't find a user-specified default for the parameter, it returns a given value.
%
%   Inputs:
%       - param_name: name of the parameter.
%       - default_value: Value to use if this parameter wasn't configured by user.
%
%   Output: The user-configured parameter value, if exists, otherwise returns the value of
%   'default_value'.
%

% Set default if not provided
if nargin < 2
    default_value = [];
end

% Set provided default value
param_value = default_value;

% If no defaults were loaded, we don't have anything to do
global rhrv_default_values;
if isempty(rhrv_default_values)    
    return;
end

% Get the 'path' to the field in the parameter struct
field_path = strsplit(param_name, '.');
curr_val = rhrv_default_values;

% Traverse into the parameters structure until the parameter is found
for ii = 1:length(field_path)
    % Make sure current field exists
    if isfield(curr_val, field_path{ii})
        curr_val = curr_val.(field_path{ii});
    else
        % Field doesn't exist so break out of loop and return the provided default.
        break;
    end
    
    % Last iteration and field existed: return it's value as the parameter
    if ii == length(field_path)
        param_value = curr_val;

        % Convert simple cell arrays (e.g. {[1],[2]}) to regular vectors.
        if iscell(param_value) && size(param_value,1) && ~iscellstr(param_value) && all(cellfun(@isscalar, param_value))
            param_value = cell2mat(param_value);
        end
    end
end

end
