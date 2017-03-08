function [ chan, Fs, N ] = get_signal_channel( rec_name, varargin )
%GET_SIGNAL_CHANNEL Find the channel of a signal in the record matching a description.
%   By default, if no description is specified it looks for ECG signal channels.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - 'sig_regex': A regular expression that should match the desired signal's description in
%                          the header file.
%           - 'comment_regex': A regular expression that matches the comment format in the header file.
%   Output:
%       - chan: Number of the first channel in the signal that matches the description regex, or an
%               empty array if no signals match.
%       - Fs: Sampling frequency
%       - N: Number of samples

% DEFAULTS
DEFAULT_SIG_REGEX = 'ECG|lead\si+|MLI+|v\d'; % Default is a regex for finding SCG signals in the Physionet files
DEFAULT_COMMENT_REGEX = '^\s*#.*';

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('sig_regex', DEFAULT_SIG_REGEX, @isstr);
p.addParameter('comment_regex', DEFAULT_COMMENT_REGEX, @isstr);

% Get input
p.parse(rec_name, varargin{:});
sig_regex = p.Results.sig_regex; % regex for the desired signal
comment_regex = p.Results.comment_regex; % regex for comment line in the header file

% default value if we can't find the description
chan = [];

% Open the header file of the record for reading
fheader = fopen([rec_name, '.hea']);

% Read lines in the header file until a match is found
i = 1;
first_line = true; % first non-comment line is the 'record line', we need to skip it
line = fgetl(fheader);
while ischar(line)
    
    % if line is not a comment line, test it
    if (isempty(regexpi(line, comment_regex)))
        
        % Skip the first non-comment line because it's the 'record line'
        if first_line
            first_line = false;
            record_line = strsplit(line, ' ');
            Fs = str2double(record_line{3});
            N  = str2double(record_line{4});
        else
            
            % if line matches the description (partial match), return it's index
            if (~isempty(regexpi(line, sig_regex)))
                chan = i;
                break;
            else
                i = i+1;
            end
        end
    end
    
    line = fgetl(fheader);
end

fclose(fheader);

end