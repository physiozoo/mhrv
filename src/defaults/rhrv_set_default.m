function [] = rhrv_set_default( varargin )
%RHRV_SET_DEFAULT Sets (overrides) current default parameter value(s) with new values.
%   Usage:
%       rhrv_set_default('param1', value1, 'param2', value2, ...)
%
%   This function allows overriding specific parameters with custom values given
%   to the function. The input should consist of key-value pairs, where the keys use the '.'
%   character to separate heirarchy levels (e.g. 'rqrs.gqconf').
%

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
global rhrv_default_values;

% Override existing values
for ii = 1:2:length(extra_params)
    fieldnames = strsplit(extra_params{ii}, '.');
    rhrv_default_values = setfield(rhrv_default_values, fieldnames{:}, extra_params{ii+1});
end



end