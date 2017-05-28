function [ param_value ] = rhrv_default( param_name, default_value )
%RHRV_DEFAULT Finds the default value configured for a parameter.
%   This function attemps to get the value of a parameter as configured by a user config file.
%   If it can't find a user-specified default for the parameter, it returns a given value.
%   This is a helper function for functions in the rhrv toolbox. It's not meant to be used directly.
%   Inputs:
%       - param_name: name of the parameter.
%       - default_value: Value to use if this parameter wasn't configured by user.
%
%   Output: The user-configured parameter value, if exists, otherwise returns the value of
%   'default_value'.
%

global rhrv_default_values;
param_value = default_value;

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
        break;
    end
    
    % Last iteration and field existed: return it's value as the parameter
    if ii == length(field_path)
        param_value = curr_val;
    end
end

end