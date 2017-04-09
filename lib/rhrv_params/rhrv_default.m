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
if(isempty(rhrv_default_values) || ~rhrv_default_values.isKey(param_name))
    param_value = default_value;
    return;
end

param_value = rhrv_default_values(param_name);

end