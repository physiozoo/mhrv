function [ param_default ] = mhrv_get_default( param_id, meta )
%Returns the default value configured for a parameter.  This function attemps
%to get the value of a parameter as configured by a user config file.  If it
%can't find a user-specified default for the parameter, it throws an error.
%
%:param param_id: Unique id of the parameter This is made up of the keys in the
%   defaults file leading to the parameter (not including the 'value' key), joined
%   by a '.' character (example: 'hrv_freq.methods').
%
%:param meta: Optional. A fieldname to return from the parameter structure
%   (instead of the structure itself). Can be value/description/name/units.
%
%:returns: A structure containing the following fields:
%
%   - value: The user-configured parameter value, if exists, otherwise returns
%     the 'default_value'.
%   - name: The user-friendly/display name of the parameter.
%   - description: A description about the parameter.
%   - units: The units the parameter is specified in.
%
%.. note::
%   If a value for 'meta' was specified, only the corresponding field will be returned.

import mhrv.defaults.*;

% If no defaults were loaded, it's an error
global mhrv_default_values;
if isempty(mhrv_default_values)    
    error('No defaults were loaded! Run mhrv_init or mhrv_load_defaults.');
end

% Split the "path" to the field in the parameter struct
field_path = strsplit(param_id, '.');
if strcmp(field_path{end}, 'value')
    field_path = field_path(1:end-1);
end

% Get the data in the field corresponding to the given param_id
try
    field_data = getfield(mhrv_default_values, field_path{:});
catch
    error('Parameter %s doesn''t exist', param_id);
end

% Check the data in the field
if ~isstruct(field_data)
    % If the field is not a structure, we'll wrap it in a metadata object
    param_default = mhrv.defaults.mhrv_parameter(field_data);
elseif isfield(field_data, 'value')
    % If the field is a parameter struct return it
    param_default = field_data;
else
    % Otherwise, the param_id points to some intermediate structure
    error('The specified param_id (%s) doesn''t correspond to a parameter value', param_id);
end

% Return only one of the metadata field if requested.
if nargin > 1
    param_default = param_default.(meta);
end

end
