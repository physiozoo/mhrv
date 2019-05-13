function [ defaults_map ] = mhrv_get_all_defaults(params_struct)
%Returns all parameter default values of the mhrv toolbox in a map.
%
%:param params_struct: Optional. The parameter structure to work on. If not
%   provided, this function will search traverse the globally defined toolbox
%   parameters.
%
%The returned map contains keys that correspond the the unique id's of
%parameters, e.g ``dfa.n_max``.  The map's values are structures containing the
%value of the parameter and metadata fields.
%

import mhrv.defaults.*;

global mhrv_default_values;
if nargin == 0
    % Use global default parameters structure
    params_struct = mhrv_default_values;
elseif ~isstruct(params_struct)
    error('Provided parameter must be a struct');
end

% Traverse the structure and add all parameters as keys to a map
defaults_map = recurse_defaults_struct('', params_struct, containers.Map);
end

%% Helper function to recursively traverse the defaults structure
function output_map = recurse_defaults_struct(curr_path, curr_element, output_map)
    % If the current element is not a struct, wrap it in a default parameter object before adding to
    % the map.
    if ~isstruct(curr_element)
        if ~isempty(curr_path)
            output_map(curr_path) = mhrv.defaults.mhrv_parameter(curr_element);
        end
        return;
    end
    
    % If the current element is a parameter structure, add it to the map as-is.
    if isfield(curr_element, 'value')
        output_map(curr_path) = curr_element;
        return;
    end
    
    % Otherwise traverse all fields
    fields = fieldnames(curr_element);
    for ii = 1:length(fields)
        field = fields{ii};
        sep = '.';
        if isempty(curr_path); sep = ''; end
        recurse_defaults_struct([curr_path sep field], curr_element.(field), output_map);
    end
end

