function [ ann ] = rdann( rec_name, ann_ext, varargin )
%RDANN Wrapper for WFDB's 'rdann' tool.
%   Reads annotation files in PhysioNet format and returns them as a MATLAB vector.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - ann_ext: Extension of annotation file. E.g. use 'qrs' is the annotation file is
%                  mitdb/100.qrs.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - 'ann_types': A double-quoted string of PhysioNet annotation types that should be read,
%                          e.g. '"N|"' to read both annotations of type 'N' and type '|'. Default is
%                          empty, i.e. return annotations of any type.
%   Output:
%       - ann: A vector with the sample numbers containing the annotations.

%% === Input

% Defaults
DEFAULT_ANN_TYPES = '';

% Define input
p = inputParser;
p.addRequired('rec_name', @(x) isrecord(x, ann_ext));
p.addRequired('ann_ext', @isstr);
p.addParameter('ann_types', DEFAULT_ANN_TYPES, @ischar);

% Get input
p.parse(rec_name, ann_ext, varargin{:});
ann_types = p.Results.ann_types;

%% === Run rdann
[rec_path, rec_filename, ~] = fileparts(rec_name);

% Command to run rdann and cut only the annotation samples out
rdann_path = get_wfdb_tool_path('rdann');
command = sprintf('%s -e -r %s -a %s', rdann_path, rec_filename, ann_ext);

% Add annotation types flag if necessary
if (~isempty(ann_types))
    command = sprintf('%s -p %s', command, ann_types);
end

[res, out] = jsystem(command, [], rec_path);
if(res ~= 0)
    error('rdann error: %s', out);
end

% Extract just the sample numbers from the rdann output
if (~isempty(out))
    [ann, ~, errmsg] = sscanf(out, '%*s %d %*[^\n]');
    if ~isempty(errmsg)
        error(['Failed to convert rdann output to samples: ' errmsg]);
    end
else
    ann = [];
end

% add 1 to all values because WFDB's indices are zero-based
ann = ann + 1;

end

