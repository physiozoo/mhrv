function [] = mhrv_set_default( varargin )
%Sets (overrides) current default parameter value(s) with new values.
%
%Usage:
%   .. code-block:: matlab
%
%       mhrv_set_default('param1', value1, 'param2', value2, ...)
%
%This function allows overriding specific parameters with custom values given
%to the function. The input should consist of key-value pairs, where the keys
%use the '.' character to separate heirarchy levels (e.g. 'rqrs.gqconf').
%

import mhrv.defaults.*;

%% Validate input

% Make sure input length makes sense
if length(varargin) < 2
    error('At least one key-value pair should be provided');
end

% Check number of parameters to determine usage type
if mod(length(varargin), 2) ~= 0
    error('Input must consist of key-value pairs');
else
    extra_params = varargin;
end

% Make sure extra params keys are strings
if ~all(cellfun(@ischar, extra_params(1:2:end)))
    error('Keys must be strings');
end

%% Override parameters

% Get the global parameters variable
global mhrv_default_values;

% Override existing values
for ii = 1:2:length(extra_params)
    field_path = strsplit(extra_params{ii}, '.');
    new_value = extra_params{ii+1};

    % If the new value is a struct with metadata, set it directly
    if isfield(new_value, 'value')
        mhrv_default_values = setfield(mhrv_default_values, field_path{:}, new_value);
        continue;
    end

    % Otherwise, set the value field at the given path, or create a new parameter with metadata
    try
        % Try to get the field value at the given path
        field_data = getfield(mhrv_default_values, field_path{:});
        % If the field data contains metadata, just change the value subfield
        if isfield(field_data, 'value')
            value_path = [field_path, 'value'];
            mhrv_default_values = setfield(mhrv_default_values, value_path{:}, new_value);
        else
            % Replace the field data with a metadata object containing the new value
            mhrv_default_values = setfield(mhrv_default_values, field_path{:}, mhrv_parameter(new_value));
        end
    catch
        % Field doesn't exist, so add it with the given value, and set empty metadata
        mhrv_default_values = setfield(mhrv_default_values, field_path{:}, mhrv_parameter(new_value));
    end
end

end
