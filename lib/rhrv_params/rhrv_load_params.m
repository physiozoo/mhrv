function [] = rhrv_load_params( varargin )
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

%% Validate input

% Make sure we have parameters
if isempty(varargin)
    error('Must provide filename and/or key-value pairs');
end

% Check number of parameters to determine usage type
if mod(length(varargin), 2) ~= 0
    % Odd number of parameters: treat the first as a filename, and the rest as key-values
    params_filename = varargin{1};
    extra_params = varargin(2:end);
else
    % Even number of parameters: no filename, all are key-values
    params_filename = '';
    extra_params = varargin;
end

% Make sure extra params keys are strings
if ~all(cellfun(@ischar, extra_params(1:2:end)))
    error('Extra parameters names must be strings');
end

% Get path to parameters file
if ~isempty(params_filename)
    % Add extension if it's not there
    [~,~,ext] = fileparts(params_filename);
    if isempty(ext)
        params_filename = [params_filename '.yml'];
    elseif strcmpi(ext, '.yml') ~= 0
        error('Only .yml files are supported as parameter files');
    end
    
    % Try to find the parameters file on the MATLAB path, and if it's not there treat it as an
    % absolue or relative path.
    w = which(params_filename);
    if ~isempty(w)
        params_filename = w;
    elseif ~exist(params_filename, 'file')
        error('Cant''t find specified parameters file');
    end
end

%% Set parameters

params = struct;

% If parameters filename was provided, load it
if ~isempty(params_filename)
    params = ReadYaml(params_filename);
end

% If extra parameters were provided, add them to the parameters (overrides existing)
for ii = 1:2:length(extra_params)
    fieldnames = strsplit(extra_params{ii}, '.');
    params = setfield(params, fieldnames{:}, extra_params{ii+1});
end

% Set the global parameters variable (so the loaded parameters affect the defaults for all toolbox
% functions).
global rhrv_default_values;
rhrv_default_values = params;

end