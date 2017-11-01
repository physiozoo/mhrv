function [ t, sig, Fs ] = rdsamp( rec_name, varargin )
%RDSAMP Wrapper for WFDB's 'rdsamp' tool.
%   Reads channels in PhysioNet data files and returns them in a MATLAB matrix.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - 'sig_list': A list of channel numbers (starting from 1) to read from the record, e.g.
%                        to read the first three channels use [1, 2, 3]. Default is [], i.e. read
%                        all channels from the record.
%           - 'from': Number of first sample to start detecting from (default 1)
%           - 'to': Number of last sample to detect until (default [], i.e. end of signal)
%   Output:
%       - t: A vector with the sample times in seconds.
%       - sig: A matrix where is column is a different channel from the signal.
%       - Fs: The sampling frequency of the data.

%% === Input

% Defaults
DEFAULT_SIG_LIST = [];
DEFAULT_FROM_SAMPLE = 1;
DEFAULT_TO_SAMPLE = [];

% Define input
p = inputParser;
p.addRequired('rec_name', @isrecord);
p.addOptional('sig_list', DEFAULT_SIG_LIST, @isvector);
p.addParameter('from', DEFAULT_FROM_SAMPLE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('to', DEFAULT_TO_SAMPLE, @(x) isnumeric(x) && (isscalar(x)||isempty(x)));

% Get input
p.parse(rec_name, varargin{:});
sig_list = p.Results.sig_list;
from_sample = p.Results.from;
to_sample = p.Results.to;

%% === Run rdsamp

% Create a random suffix for the output file extension (this prevents collisions when running on
% the same file in parallel)
suffix = num2str(randi(999999));
out_ext = ['rdsamp' suffix];

[rec_path, rec_filename, ~] = file_parts(rec_name);
temp_filename = sprintf('%s.%s', rec_filename, out_ext);
temp_file = [rec_path filesep temp_filename];

% Command to run rdann with natural units
rdsamp_path = get_wfdb_tool_path('rdsamp');
command = sprintf('%s -P -c -r %s -f s%d', rdsamp_path, rec_filename, from_sample-1);
if (~isempty(to_sample))
    command = sprintf('%s -t s%d', command, to_sample-1);
end

% Check if we only need part of the signals
if (~isempty(sig_list))
    % convert signal list to string, and make it zero-based
    sig_list_str = mat2str(sig_list - 1);
    if (length(sig_list) > 1)
        sig_list_str = sig_list_str(2:end-1); % remove brackets
    end
    command = sprintf('%s -s %s', command, sig_list_str);
end

% run the command and write results to a temp file
command = sprintf('%s > %s', command, temp_filename);
[res, out, err] = jsystem(command,[], rec_path);
if(res ~= 0)
    error('rdsamp error: %s\n%s', err, out);
end

M = dlmread(temp_file, ',');
t = M(:,1);
sig = M(:,2:end);
Fs = floor(size(sig,1) / (t(end) - t(1))); % since tm is in seconds

% Delete the temp file
delete(temp_file);
end

