function [ files_written ] = wrann( rec_name, ann_ext, ann_idx, varargin )
%Wrapper for WFDB's 'wrann' tool.  Write annotation files in PhysioNet format
%given a MATLAB vector.
%
%:param rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100.  If
%   a header file for the record doesn't exist one will be created (but fs must be
%   specified in varargin).
%:param ann_ext: Extension of annotation file to write. E.g. use 'qrs' to write
%   the annotation file mitdb/100.qrs.
%:param ann_idx: A column vector of integer type containing sample indices of
%   the annotations.
%:param varargin: Pass in name-value pairs to configure %advanced options:
%
%   - fs: The sampling frequency of the signal which is being annotated. Pass
%     this in if writing annotations for a record which doesn't exist (i.e. a
%     header file should be created).
%   - comments: A cell array of strings which will bea written to the header
%     file as comments (one per line). Will only be written when a new header
%     file is craeted by this function.
%   - type: Either a single character that will be used as the type for all
%     annotations, or a cell array the same size 'ann_idx' containg a different
%     annotation type per sample.
%   - sub: Either a single number (-128 ~ 128) that will be used as the subtype
%     attribute for all annotations, or a column vector the same size as
%     'ann_idx' containg a different subtype per sample.
%   - chan: Either a single number (-128 ~ 128) that will be used as the chan
%     attribute for all annotations, or a column vector the same size as
%     'ann_idx' containg a different chan per sample.
%   - num: Either a single number (-128 ~ 128) that will be used as the num
%     attribute for all annotations, or a column vector the same size as
%     'ann_idx' containg a different num per sample.
%   - aux: Either a single string that will be used as the aux attribute for
%     all annotations, or a string cell array the same size as 'ann_idx' containg
%     a different aux per sample.
%
%:returns: A cell array with the paths of files that were created.

import mhrv.wfdb.*;

%% === Input

% Defaults
DEFAULT_TYPE = 'N';
DEFAULT_SUB = int8(0);
DEFAULT_CHAN = int8(0);
DEFAULT_NUM = int8(0);
DEFAULT_AUX = '';

% Define input
p = inputParser;
p.addRequired('rec_name', @(x) ischar(x) && ~isempty(x));
p.addRequired('ann_ext', @(x) ischar(x) && ~isempty(x));
p.addRequired('ann_idx', @(x) isnumeric(x) && ~isempty(x));
p.addParameter('fs', [], @(x) isscalar(x) && x > 0);
p.addParameter('comments', {}, @(x)iscellstr(x));
p.addParameter('type', DEFAULT_TYPE, @(x)ischar(x)||iscellstr(x));
p.addParameter('sub', DEFAULT_SUB, @isnumeric);
p.addParameter('chan', DEFAULT_CHAN, @isnumeric);
p.addParameter('num', DEFAULT_NUM, @isnumeric);
p.addParameter('aux', DEFAULT_AUX, @(x)ischar(x)||iscellstr(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, ann_ext, ann_idx, varargin{:});
p = p.Results;

% Init output
files_written = {};

%% Validate input

if ~isinteger(ann_idx)
    warning('ann_idx is not of integer type. It will be converted to uint32');
end
ann_idx = uint32(ann_idx);
ann_idx = ann_idx(:);

% Go over fields, validate their type and length. If length is 1,
% replicate to length of ann_idx.
fields_to_validate = {'type', 'sub', 'chan', 'num', 'aux'};
for ii = 1:length(fields_to_validate)
    field_name = fields_to_validate{ii};
    field_value = p.(field_name);
    
    if isnumeric(field_value)
        if ~isa(field_value, 'int8')
            warning('%s is not of int8 type. It will be converted to int8', field_name);
            field_value = int8(field_value);
        end
    end
    
    if ischar(field_value)
        field_value = {field_value};
    end
    
    if iscellstr(field_value) && strcmp(field_name, 'type')
        if any(cellfun(@(t) length(t) ~= 1, field_value))
            error('Annotation type must be a single character.');
        end
    end
    
    if length(field_value) == 1
        field_value = repmat(field_value, size(ann_idx));
    end
    
    if length(field_value) ~= length(ann_idx)
        error('Length of %s doesn''t match number of annotations in ann_idx', field_name);
    end
    
    field_value = reshape(field_value, size(ann_idx));
    
    p.(field_name) = field_value;
end


if ~isrecord(rec_name, 'hea')
    if isempty(p.fs)
        error('No header found for record %s and fs wasn''t specified', rec_name);
    else
        % Create a basic header file to allow wrann to work
        header_filename = [rec_name '.hea'];
        fid = fopen(header_filename, 'w');

        % Header line
        [~, rec_name_no_path, ~] = file_parts(rec_name);
        fprintf(fid, '%s 0 %f 0\n', rec_name_no_path, p.fs);

        % Comment lines
        for jj = 1:length(p.comments)
            comment = regexprep(p.comments{jj}, '(\r?\n)', '$1# ');
            fprintf(fid, '# %s\n', comment);
        end

        fclose(fid);
        files_written{end+1} = header_filename;
    end
end

%% Write annotation as text

% Create a fake time column. We need this because wrann expects it. However
% the values themselves don't matter in this case since we want times
% relative to the start of the record and the sample numbers are used to
% calcualte relative times.
% See comment at the bottom of the description section here:
% https://www.physionet.org/physiotools/wag/wrann-1.htm
time_col = repmat({'00:00:00.000'}, size(ann_idx));

% Create a table with all the data for wrann
wrann_data_table =...
    table(time_col, ann_idx, p.type, p.sub, p.chan, p.num, p.aux,...
    'VariableNames', {'Time', 'Sample', 'Type', 'Sub', 'Chan', 'Num', 'Aux'});

% Write the table to a file
temp_file_name = [tempname '.txt'];
writetable(wrann_data_table, temp_file_name,...
    'Delimiter', 'space', 'WriteVariableNames', false);

%% Run wrann
try
    [rec_path, rec_filename, ~] = file_parts(rec_name);

    wrann_path = get_wfdb_tool_path('wrann');
    command = sprintf('%s -r %s -a %s < %s', wrann_path, rec_filename, ann_ext, temp_file_name);

    [res, out, err] = jsystem(command, [], rec_path);
    if(res ~= 0)
        error('wrann error: %s\n%s', err, out);
    end
    
    files_written{end+1} = [rec_name '.' ann_ext];
catch e
    delete(temp_file_name);
    rethrow(e);
end

%% Cleanup
if exist(temp_file_name, 'file')
    delete(temp_file_name);
end

end

