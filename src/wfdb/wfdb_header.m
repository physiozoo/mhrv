function [ Fs, N_samples, N_channels, channel_info ] = wfdb_header( rec_name )
%WFDB_HEADER Returns metadata about a WFDB record based on it's header file
%   By default, if no description is specified it looks for ECG signal channels.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%
%   Output:
%       - Fs: Sampling frequency
%       - N_samples: Number of samples
%       - N_channels: Number of channels (different signals) in the record
%       - channel_info: A cell array of length N_channels with the metadata about each channel

% DEFAULTS
COMMENT_REGEX = '^\s*#.*';
FORMAT_REGEX = '(\d+)(x\d+)?(:\d+)?(+\d+)?';
ADC_GAIN_REGEX = '([\d.-+]+)(\(\d+\))?(/.*)?';
DEFGAIN = 200;

% Define input
p = inputParser;
p.addRequired('rec_name', @(x) isrecord(x, 'hea'));

% Get input
p.parse(rec_name);

% Open the header file of the record for reading
fheader = fopen([rec_name, '.hea']);

try
% Read lines in the header file until a match is found
channel_idx = 0;
first_line = true; % first non-comment line is the 'record line', we need to skip it
line = fgetl(fheader);
while ischar(line)
    
    % if line is not a comment line, test it
    if (isempty(regexpi(line, COMMENT_REGEX)))
        split_line = strsplit(line);
        
        % Skip the first non-comment line because it's the 'record line'
        if first_line
            first_line = false;
            
            N_channels = str2double(split_line{2});
            Fs = str2double(split_line{3});
            N_samples  = str2double(split_line{4});
            channel_info = cell(1, N_channels);
        else
            % Note: parsing of signal line here is based on WFDB header file format documentation:
            % https://physionet.org/physiotools/wag/header-5.htm

            channel_idx = channel_idx + 1;
            channel_info{channel_idx} = struct;

            % At least two non-optional fields must exst in the signal line
            if length(split_line) < 2
                error('Not enough field in record header line, channel = %d', chan_idx);
            end
            
            % First field is filename
            channel_info{channel_idx}.filename = split_line{1};
            
            % Second field: 'format' and optionally 'samples per frame', 'skew' and 'byte offset'
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
            
            % Third field: 'ADC Gain' and optionally 'baseline' and 'units'
            if length(split_line) < 3
                channel_info{channel_idx}.adc_gain = DEFGAIN;
                continue;
            end
            tokens = regexpi(split_line{3}, ADC_GAIN_REGEX, 'tokens'); tokens = tokens{1};
            channel_info{channel_idx}.adc_gain = str2double(tokens{1});
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
                channel_info{channel_idx}.description = split_line{9};
            end
            
            % If the baseline wasn't provided in thethird field, it should be set to ADC zero if
            % that was provided, or zero if not
            if ~isfield(channel_info{channel_idx}, 'baseline')
                if isfield(channel_info{channel_idx}, 'adc_zero')
                    channel_info{channel_idx}.baseline = channel_info{channel_idx}.adc_zero;
                else
                    channel_info{channel_idx}.baseline = 0;
                end
            end
        end
    end
    
    line = fgetl(fheader);
end
catch e
    % Make sure to close the file on any error
    fclose(fheader);
    throw(e);
end

fclose(fheader);

end

