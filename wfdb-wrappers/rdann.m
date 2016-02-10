function [ ann ] = rdann( rec_name, ann_ext, varargin )
%RDANN Wrapper for WFDB's 'rdann'
%   Detailed explanation goes here

%% === Input

% Defaults
DEFAULT_ANN_TYPES = '';

% Define input
p = inputParser;
p.addRequired('rec_name', @isrecord);
p.addRequired('ann_ext', @isstr);
p.addParameter('ann_types', DEFAULT_ANN_TYPES, @ischar);

% Get input
p.parse(rec_name, ann_ext, varargin{:});
ann_types = p.Results.ann_types;

%% === Run rdann

% Command to run rdann and cut only the annotation samples out
command = sprintf('rdann -e -r %s -a %s', rec_name, ann_ext);

% Add annotation types flag if necessary
if (~isempty(ann_types))
    command = sprintf('%s -p %s', command, ann_types);
end

% Pipe to awk to cut the second column of the output (sample numbers)
 command =[command, ' | awk ''{print $2}'''];

[res, out] = jsystem(command);
if(res ~= 0)
    error('rdann error: %s', out);
end

% Convert string of numbers to vector
if (~isempty(out))
    [ann, conversion_ok] = str2num(out);
    if (conversion_ok == 0)
        error('Failed to convert rdann output to samples');
    end
else
    ann = [];
end

% add 1 to all values because WFDB's indices are zero-based
ann = ann + 1;

end

