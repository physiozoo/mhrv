function [ t, sig, Fs ] = rdsamp( rec_name, varargin )
%RDSAMP Wrapper for WFDB's 'rdsamp'
%   Detailed explanation goes here

%% === Input

% Defaults
DEFAULT_SIG_LIST = [];

% Define input
p = inputParser;
p.addRequired('rec_name', @isrecord);
p.addOptional('sig_list', DEFAULT_SIG_LIST, @isvector);

% Get input
p.parse(rec_name, varargin{:});
sig_list = p.Results.sig_list;

%% === Run rdsamp

temp_file = sprintf('%s.rdsamp', rec_name);

% Command to run rdann with natural units
command = sprintf('rdsamp -r %s -P', rec_name);

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
command = sprintf('%s > %s', command, temp_file);
[res, out] = jsystem(command);
if(res ~= 0)
    error('rdann error: %s', out);
end

M = dlmread(temp_file);
t = M(:,1);
sig = M(:,2:end);
Fs = floor(1/mean(diff(t)));

% Delete the temp file
delete(temp_file);

end

