function [ t, sig, Fs ] = rdsamp( rec_name, varargin )
%RDSAMP Wrapper for WFDB's 'rdsamp' tool.
%   Reads channels in PhysioNet data files and returns them in a MATLAB matrix.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - 'chan_list': A list of channel numbers (starting from 1) to read from the record, e.g.
%                        to read the first three channels use [1, 2, 3]. Default is [], i.e. read
%                        all channels from the record.
%           - 'from': Number of first sample to start detecting from (default 1)
%           - 'to': Number of last sample to detect until (default [], i.e. end of signal)
%   Output:
%       - t: A vector with the sample times in seconds.
%       - sig: A matrix where is column is a different channel from the signal.
%       - Fs: The sampling frequency of the data.

%% Input

% Defaults
DEFAULT_CHAN_LIST = [];
DEFAULT_FROM_SAMPLE = 1;
DEFAULT_TO_SAMPLE = [];

% Define input
p = inputParser;
p.addRequired('rec_name', @isrecord);
p.addOptional('chan_list', DEFAULT_CHAN_LIST, @(x)isempty(x)||isvector(x));
p.addParameter('header_info', [], @(x) isempty(x) || isstruct(x));
p.addParameter('from', DEFAULT_FROM_SAMPLE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('to', DEFAULT_TO_SAMPLE, @(x) isnumeric(x) && (isscalar(x)||isempty(x)));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
chan_list = p.Results.chan_list;
header_info = p.Results.header_info;
from_sample = p.Results.from;
to_sample = p.Results.to;
should_plot = p.Results.plot;

% Validate header info
if isempty(header_info)
    header_info = wfdb_header(rec_name);
elseif ~strcmp(rec_name, header_info.rec_name)
    error('Provided header_info was for a different record');
end

%% Run rdsamp

% Create a random suffix for the output file extension (this prevents collisions when running on
% the same file in parallel)
suffix = num2str(randi(999999));
out_ext = ['rdsamp' suffix];

[rec_path, rec_filename, ~] = file_parts(rec_name);
temp_filename = sprintf('%s.%s', rec_filename, out_ext);
temp_file = [rec_path filesep temp_filename];

% Command to run rdsamp
rdsamp_path = get_wfdb_tool_path('rdsamp');
command = sprintf('%s -c -r %s -f s%d', rdsamp_path, rec_filename, from_sample-1);
if (~isempty(to_sample))
    command = sprintf('%s -t s%d', command, to_sample-1);
end

% Check if we only need part of the signals
if (~isempty(chan_list))
    % convert signal list to string, and make it zero-based
    chan_list_str = mat2str(chan_list - 1);
    if (length(chan_list) > 1)
        chan_list_str = chan_list_str(2:end-1); % remove brackets
    end
    command = sprintf('%s -s %s', command, chan_list_str);
end

% run the command and write results to a temp file
command = sprintf('%s > %s', command, temp_filename);
[res, out, err] = jsystem(command,[], rec_path);
if(res ~= 0)
    error('rdsamp error: %s\n%s', err, out);
end

% Load contents of temp file
M = dlmread(temp_file, ',');

% Delete the temp file
delete(temp_file);

%% Convert to physical units
% Note: We don't use the '-P' option of rdsamp because it doesn't handle NaN (missing) values in the
% signal correctly.

% Get channel metadata from header file
Fs = header_info.Fs;
channel_info = header_info.channel_info;

% Get channel info for requested channels only
if (~isempty(chan_list))
    channel_info = channel_info(chan_list);
end

t = M(:,1) .* (1/Fs);

sig = zeros(size(M,1), size(M,2)-1);
for chan_idx = 1:size(sig,2)
    baseline = channel_info{chan_idx}.baseline;
    adc_gain = channel_info{chan_idx}.adc_gain;

    sig(:,chan_idx) = (M(:,chan_idx+1) - baseline) ./ adc_gain;
end

%% Plot
if (should_plot)
    figure('Name', rec_name);

    for ii = 1:length(channel_info)
        channel_disp_name = channel_info{ii}.description;
        plot(t, sig(:,ii), 'DisplayName', channel_disp_name);
        hold on;
    end

    xlabel('time (s)');
    grid on;
    legend();
end

end

