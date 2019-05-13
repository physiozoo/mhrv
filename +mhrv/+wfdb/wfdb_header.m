function [ header_info ] = wfdb_header( rec_name )
%Returns metadata about a WFDB record based on it's header file.
%
%:param rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if
%   the record files (both 100.dat and 100.hea) are in a folder named 'db/mitdb'
%   relative to MATLABs pwd.
%
%:returns: A struct with the following fields:
%
%   - rec_name: The record name
%   - Fs: Sampling frequency
%   - N_samples: Number of samples
%   - N_channels: Number of channels (different signals) in the record
%   - channel_info: A cell array of length N_channels with the metadata about
%     each channel
%   - duration: A struct with the fields h,m,s,ms corresponding to duration
%     fields - hours, miutes, seconds, milliseconds.
%   - total_seconds: Records total duration in seconds.
%
%.. note::
%   If no output arguments are given, prints record and channel info to console.
%

import mhrv.wfdb.*

% DEFAULTS
COMMENT_REGEX = '^\s*#\s*(.*)?';
FORMAT_REGEX = '(\d+)(x\d+)?(:\d+)?(+\d+)?';
ADC_GAIN_REGEX = '([\d.-+]+)(\([\d.-+]+\))?(/.*)?';
DEFGAIN = 200;

% Define input
p = inputParser;
p.addRequired('rec_name', @(x) isrecord(x, 'hea'));

% Get input
p.parse(rec_name);

% Open the header file of the record for reading
fheader = fopen([rec_name, '.hea']);

try
% first non-comment line is the 'record line', we need to skip it
first_line = true;

channel_idx = 0;
comments = {};

% Read lines in the header file until a match is found
while true
    % Read next line from file
    line = fgetl(fheader);
    if line == -1
        break;
    end

    % Save comment lines
    comment_tokens = regexpi(line, COMMENT_REGEX, 'tokens');
    if (~isempty(comment_tokens))
        comments{end+1} = comment_tokens{1}{1};
        continue;
    end

    split_line = strsplit(line);

    % The first non-comment line is the 'record line'.
    if first_line
        first_line = false;

        N_channels = str2double(split_line{2});
        Fs = str2double(split_line{3});
        N_samples  = str2double(split_line{4});
        channel_info = cell(1, N_channels);
        continue;
    end

    % The rest of the non-comment lines are signal (channel) lines.
    % Note: parsing of signal line here is based on WFDB header file format documentation:
    % https://physionet.org/physiotools/wag/header-5.htm

    % At least two non-optional fields must exist in the signal line
    if length(split_line) < 2
        error('Not enough field in record header line, channel = %d', chan_idx);
    end

    % Initialize struct for current channel metadata
    channel_idx = channel_idx + 1;
    channel_info{channel_idx} = struct;

    % First field is filename
    channel_info{channel_idx}.filename = split_line{1};

    % Second field - 'format' and optionally 'samples per frame', 'skew' and 'byte offset':
    % <format>x<samples_per_frame>:<skew>+<byte_offset>
    tokens = regexpi(split_line{2}, FORMAT_REGEX, 'tokens'); tokens = tokens{1};
    channel_info{channel_idx}.format = str2double(tokens{1});
    if ~isempty(tokens{2})
        channel_info{channel_idx}.samples_per_frame = str2double(tokens{2}(2:end));
    end
    if ~isempty(tokens{3})
        channel_info{channel_idx}.skew = str2double(tokens{3}(2:end));
    end
    if ~isempty(tokens{4})
        channel_info{channel_idx}.byte_offset = str2double(tokens{4}(2:end));
    end

    % Third field - 'ADC Gain' and optionally 'baseline' and 'units':
    % <ADC_Gain>(<baseline>)/<units>
    if length(split_line) < 3
        % Set defaults for gain and baseline if they are missing,
        % according to the documentation
        channel_info{channel_idx}.adc_gain = DEFGAIN;
        channel_info{channel_idx}.baseline = 0;
        continue;
    end
    tokens = regexpi(split_line{3}, ADC_GAIN_REGEX, 'tokens'); tokens = tokens{1};
    channel_info{channel_idx}.adc_gain = str2double(tokens{1});
    if (channel_info{channel_idx}.adc_gain == 0)
        % If gain was specified but it's value is zero, it should be set to DEFGAIN
        % according to the documentation
        channel_info{channel_idx}.adc_gain = DEFGAIN;
    end
    if ~isempty(tokens{2})
        channel_info{channel_idx}.baseline = str2double(tokens{2}(2:end-1));
    end
    if ~isempty(tokens{3})
        channel_info{channel_idx}.units = tokens{3}(2:end);
    end

    % ADC Resolution
    if length(split_line) > 3
        channel_info{channel_idx}.adc_resolution = str2double(split_line{4});
    end
    % ADC Zero
    if length(split_line) > 4
        channel_info{channel_idx}.adc_zero = str2double(split_line{5});
    end
    % Initial value
    if length(split_line) > 5
        channel_info{channel_idx}.initial_value = str2double(split_line{6});
    end
    % Checksum
    if length(split_line) > 6
        channel_info{channel_idx}.checksum = str2double(split_line{7});
    end
    % Block size
    if length(split_line) > 7
        channel_info{channel_idx}.block_size = str2double(split_line{8});
    end
    % Description
    if length(split_line) > 8
        channel_info{channel_idx}.description = strjoin(split_line(9:end), ' ');
    end

    % According to the documentation, if the baseline wasn't provided in the third field,
    % it should be set to ADC zero if that was provided, or zero if not
    if ~isfield(channel_info{channel_idx}, 'baseline')
        if isfield(channel_info{channel_idx}, 'adc_zero')
            channel_info{channel_idx}.baseline = channel_info{channel_idx}.adc_zero;
        else
            channel_info{channel_idx}.baseline = 0;
        end
    end
end
catch e
    % Make sure to close the file on any error
    fclose(fheader);
    throw(e);
end

fclose(fheader);

%% Create output struct

[t_max, h,m,s,ms] = signal_duration(N_samples, Fs);

header_info = struct(...
    'rec_name', rec_name,...
    'Fs', Fs, 'N_samples', N_samples, 'N_channels', N_channels, 'channel_info', {channel_info},...
    'duration', struct('h', h, 'm', m, 's', s, 'ms', ms),...
    'total_seconds', t_max,...
    'comments', {comments}...
);

%% Display info

if nargout == 0
    fprintf('Record %s\n', rec_name);
    fprintf('  Duration [HH:mm:ss.ms]: %02d:%02d:%02d.%03d (%.3f seconds)\n', h,m,s,ms,t_max);
    fprintf('  Sampling frequency: %.1f\n', Fs);
    fprintf('  Samples per channel: %d\n', N_samples);
    fprintf('  Number of channels: %d\n', N_channels);
    fprintf('  Comments: %s\n', strjoin(comments, '; '));

    for ii = 1:N_channels
        fprintf('Channel %d:\n', ii);
        disp(channel_info{ii});
    end
end

end
