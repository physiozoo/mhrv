function [ parameter_object ] = rhrv_parameter( value, description, name, units )
%RHRV_PARAMETER Creates a parameter structure for use with the rhrv toolbox.
%
%   Inputs:
%       - value: The parameter's value. Can be any matlab object.
%       - description: Informative description of the parameter.
%       - name: User friendly/display name of the parameter.
%       - units: Parameters units.
%   All inputs are optional and default to an empty string if not provided.
%
%   Output:
%       An object representing the parameter. Can be added to the defaults with the rhrv_set_default
%       or rhrv_load_defaults functions.
%

%% Input validation
if nargin < 1
    value = '';
end
if nargin < 2
    description = '';
end
if nargin < 3
    name = '';
end
if nargin < 4
    units = '';
end

if  ~all([ischar(description) ischar(name) ischar(units)])
    error('All parameters except for value must be strings');
end

%% Create output
% A structure containing the parameter value and metadata
parameter_object = struct;
parameter_object.value = value;
parameter_object.description = description;
parameter_object.name = name;
parameter_object.units = units;
end