function [] = rhrv_load_params( params_filename, varargin )
%RHRV_LOAD_PARAMS Loads an rhrv parameters file, setting it's values as default.
%   Usage:
%       rhrv_load_params <params_filename>
%       rhrv_load_params(params_filename, 'param1', value1, 'param2', value2, ...)
%
%   This function loads the parameters from an rhrv parameters file and sets them as
%   the default value for the various toolbox functions.
%
%   The second usage form also allows overriding specific parameters with custom values given
%   to the function.
%

if ~isempty(varargin)
    if mod(length(varargin), 2) ~= 0
        error('Extra parameters must be key-value pairs');
    elseif ~all(cellfun(@ischar, varargin(1:2:end)))
        error('Extra parameters names must be strings');
    end
end

global rhrv_basepath;
if (isempty(rhrv_basepath))
    error('Please run rhrv_init.m before using the rhrv tools');
end

global rhrv_default_values;
rhrv_default_values = containers.Map;

% If parameters filename was provided, load it
if ~isempty(params_filename)
    % Find the function name
    if ~isempty(which(params_filename))
        params_funcname = params_filename;
    elseif ~isempty(which(['rhrv_params_' params_filename]))
        params_funcname = ['rhrv_params_' params_filename];
    else
        error('Can''t find parameters file %s', params_filename);
    end

    % Invoke the setter function
    loader_handler = str2func(params_funcname);
    loader_handler(rhrv_default_values, [rhrv_basepath filesep 'cfg']);
end

% If extra parameters were provided, add them to the parameters map
if ~isempty(varargin)
    for ii = 1:2:length(varargin)
        rhrv_default_values(varargin{ii}) = varargin{ii+1};
    end
end


end