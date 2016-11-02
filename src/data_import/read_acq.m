function [t, data, fs, info] = read_acq(filename)
%READ_ACQ Load/plot data files in *.acq format into matlab.
%
% Input:
%   filename: Path to *.acq file to read. Can be relative to pwd.
% Output:
%   t: Cell array containing the time axis values for each channel.
%   data: Cell array containing the data values for each channel.
%   fs: The sampling frequency in Hz (for all channels).
%   info: A struct containing additional information that was read form the file.
%
% If no output variables are provided, this function will plot the data (each channel in a subplot).
%

% Read raw data (use 'acqread' from matlab file exchange)
[info,data] = acqread(filename);
n_channels = double(info.nChannels);

% Calculate sampling frequency [hz]
fs = 1000 / double(info.dSampleTime); % dSampleTime is in millisec per sample

% Pre allocate time cell array
t = cell(1, n_channels);

for chan_idx = 1:n_channels
    n = length(data{chan_idx});

    % Scale the data
    scale = double(info.dAmplScale(chan_idx));
    offset = double(info.dAmplOffset(chan_idx));
    data{chan_idx} = double(data{chan_idx}) .* scale + offset;

    % Create time axis (in seconds)
    t{chan_idx} = (1/fs) .* (0:(n-1))';
end

if (nargout == 0)
    figure;
    n_markers = double(info.lMarkers);
    colors = cool(n_markers+1);
    [~, filename_without_path, ~] = fileparts(filename);

    for chan_idx = 1:n_channels
        subplot(n_channels, 1, chan_idx); grid on;
        plot(t{chan_idx}, data{chan_idx}, 'Color', 'blue');
        ylabel(info.szUnitsText(chan_idx));
        xlabel('Seconds');

        legend_entries = cell(1, n_markers+1);
        legend_entries{1} = info.szCommentText{chan_idx};

        % Add annotations
        for marker_idx = 1:n_markers
            line_x = ones(1,2) * double(info.lSample(marker_idx)) * 1/fs;
            line_y = ylim;
            line(line_x, line_y, 'LineStyle', ':', 'LineWidth', 3, 'Color', colors(marker_idx,:));
            legend_entries{marker_idx+1} = info.szText{marker_idx};
        end

        legend(legend_entries);
    end

    % Add title above all subplots
    mtit(filename_without_path);
end
