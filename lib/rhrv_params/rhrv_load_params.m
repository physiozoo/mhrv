function [] = rhrv_load_params( params_filename )
%RHRV_LOAD_PARAMS Loads an rhrv parameters file, setting it's values as default.
%   Usage:
%       rhrv_load_params <params_filename>
%
%   This function loads the parameters from an rhrv parameters file and sets them as
%   the default value for the various toolbox functions.

global rhrv_basepath;
if (isempty(rhrv_basepath))
    error('Please run bootstrap.m before using the rhrv tools');
end

global rhrv_default_values;
rhrv_default_values = containers.Map;

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