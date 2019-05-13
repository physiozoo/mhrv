function [ parameter_object ] = mhrv_parameter( value, description, name, units )
%Creates a parameter structure for use with the mhrv toolbox.
%
%:param value: The parameter's value. Can be any matlab object.
%:param description: Informative description of the parameter.
%:param name: User friendly/display name of the parameter.
%:param units: Parameters units.
%
%.. note::
%   All inputs are optional and default to an empty string if not provided.
%
%:returns:
%   An object representing the parameter. Can be added to the defaults
%   with the mhrv_set_default or mhrv_load_defaults functions.
%

import mhrv.defaults.*;

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
