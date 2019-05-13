function [] = mhrv_save_defaults( output_filename )
%Save the current default values of all parameters defined in the toolbox to a
%file.
%
%Usage:
%   .. code-block:: matlab
%
%      mhrv_save_defaults <output_filename>
%
%This function saves the current default values of all parameters in the
%toolbox to a specified output file. The file will be in YAML format. If the
%output_filename parameters doesn't specify a ``.yml`` extension, it will be added.
%

import mhrv.defaults.*;

%% Validate input

% Make sure we have parameters
if isempty(output_filename)
    error('Must provide output filename');
end

% Add extension if it's not there
[~,~,ext] = fileparts(output_filename);
if ~strcmpi(ext, '.yml')
    output_filename = [output_filename '.yml'];
end

%% Write parameters

% Load the global parameters variable into workspace
global mhrv_default_values;

% Write it to the specified path
WriteYaml(output_filename, mhrv_default_values);

end
