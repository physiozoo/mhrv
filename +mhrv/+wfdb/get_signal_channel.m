function [ chan, Fs, N ] = get_signal_channel( rec_name, varargin )
%Find the channel of a signal in the record matching a description.  By
%default, if no description is specified it looks for ECG signal channels.
%
%:param rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if
%   the record files (both 100.dat and 100.hea) are in a folder named 'db/mitdb'
%   relative to MATLABs pwd.
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - sig_regex: A regular expression that should match the desired signal's
%     description in the header file.
%   - comment_regex: A regular expression that matches the comment format in
%     the header file.
%
%:returns:
%
%   - chan: Number of the first channel in the signal that matches the
%     description regex, or an empty array if no signals match.
%   - Fs: Sampling frequency
%   - N: Number of samples
%

import mhrv.wfdb.*

% DEFAULTS
DEFAULT_SIG_REGEX = 'ECG|lead\si+|MLI+|v\d|\<I+\>'; % Default is a regex for finding SCG signals in the Physionet files


% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @(x) isrecord(x, 'hea'));
p.addParameter('header_info', [], @(x) isempty(x) || isstruct(x));
p.addParameter('sig_regex', DEFAULT_SIG_REGEX, @isstr);

% Get input
p.parse(rec_name, varargin{:});
header_info = p.Results.header_info;
sig_regex = p.Results.sig_regex; % regex for the desired signal

if isempty(header_info)
    header_info = wfdb_header(rec_name);
elseif ~strcmp(rec_name, header_info.rec_name)
    error('Provided header_info was for a different record');
end

% default value if we can't find the description
chan = [];
Fs = header_info.Fs;
N = header_info.N_samples;

channel_info = header_info.channel_info;
for ii = 1:length(channel_info)
    if ~isfield(channel_info{ii}, 'description')
        continue;
    end

    description = channel_info{ii}.description;
    if ~isempty(regexpi(description, sig_regex))
        chan = ii;
        break;
    end
end

end
