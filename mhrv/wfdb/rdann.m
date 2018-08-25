function [ ann, ann_types ] = rdann( rec_name, ann_ext, varargin )
%Wrapper for WFDB's 'rdann' tool.  Reads annotation files in PhysioNet format
%and returns them as a MATLAB vector.
%
%:param rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if
%  the record files (both 100.dat and 100.hea) are in a folder named 'db/mitdb'
%  relative to MATLABs pwd.
%:param ann_ext: Extension of annotation file. E.g. use 'qrs' is the annotation
%  file is mitdb/100.qrs.
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - 'ann_types': A double-quoted string of PhysioNet annotation types that
%     should be read, e.g. '"N|"' to read both annotations of type 'N' and type
%     '|'. Default is empty, i.e. return annotations of any type.
%   - from: Number of first sample to start detecting from (default 1)
%   - to: Number of last sample to detect until (default [], i.e. end of
%     signal)
%   - plot: Whether to plot the all the channels and annotations in the file.
%     Useful for debugging.
%
%:returns:
%
%   - ann: A Nx1 vector with the sample numbers that have annotations.
%   - ann_types: A Nx1 cell array with annotation types (strings, see PhysioNet
%     documentation).
%

%% === Input

% Defaults
DEFAULT_ANN_TYPES = '';
DEFAULT_FROM_SAMPLE = 1;
DEFAULT_TO_SAMPLE = [];

% Define input
p = inputParser;
p.addRequired('rec_name', @(x) isrecord(x, ann_ext));
p.addRequired('ann_ext', @isstr);
p.addParameter('ann_types', DEFAULT_ANN_TYPES, @ischar);
p.addParameter('from', DEFAULT_FROM_SAMPLE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('to', DEFAULT_TO_SAMPLE, @(x) isnumeric(x) && (isscalar(x)||isempty(x)));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, ann_ext, varargin{:});
ann_types = p.Results.ann_types;
from_sample = p.Results.from;
to_sample = p.Results.to;
should_plot = p.Results.plot;

%% === Run rdann
[rec_path, rec_filename, ~] = file_parts(rec_name);

% Command to run rdann and cut only the annotation samples out
rdann_path = get_wfdb_tool_path('rdann');
command = sprintf('%s -e -r %s -a %s -f s%d', rdann_path, rec_filename, ann_ext, from_sample-1);
if (~isempty(to_sample))
    command = sprintf('%s -t s%d', command, to_sample-1);
end

% Add annotation types flag if necessary
if (~isempty(ann_types))
    command = sprintf('%s -p %s', command, ann_types);
end

[res, out, err] = jsystem(command, [], rec_path);
if(res ~= 0)
    if res == 2 && isempty(err) && isempty(out)
        error('rdann: No annotations found (from=%d, to=%d)', from_sample, to_sample);
    else
        error('rdann error: %s\n%s', err, out);
    end
end

% Extract just the sample numbers from the rdann output
if (~isempty(out))
    out_parsed = textscan(out, '%*s %d %s %*[^\n]');
    ann = out_parsed{1};
    ann_types = out_parsed{2};
else
    ann = [];
    ann_types = {};
end

% add 1 to all values because WFDB's indices are zero-based
ann = ann + 1;

%% Plots

if (should_plot)
    % Get all annotation types
    ann_types_uniq = unique(ann_types);
    num_types = length(ann_types_uniq);

    if isrecord(rec_name, 'dat')
        % Read and plot the signal
        [ t, sig, ~ ] = rdsamp(rec_name, [],...
            'from', from_sample, 'to', to_sample, 'plot', true);
    else
        % We don't have an actual signal to read, so just create a fake
        % signal that has a different constant value for each annotation
        % type.
        header_info = wfdb_header(rec_name);
        num_samples = double(ann(end));
        t = linspace(0, num_samples/header_info.Fs, num_samples);
        sig = zeros(1,ann(end));
        for ii = 1:num_types
            curr_ann_type = ann_types_uniq{ii};
            curr_ann_type_idx = ann(ismember(ann_types, curr_ann_type)) - from_sample;
            sig(curr_ann_type_idx) = ii;
        end
        figure;
        yticks(gca, 1:num_types);
        ylabel(gca, 'Annotation Type');
        xlabel(gca, 'time (seconds)');
        hold(gca, 'on');
    end
    set(gcf,'Name',[rec_name ' annotations']);

    colors = lines(num_types + size(sig,2));
    markers = {'x','o','+','*','s','d','^','v','>','<','p','h','.'};
    color_idx = 1+size(sig,2);
    marker_idx = 1;

    for ii = 1:num_types
        curr_ann_type = ann_types_uniq{ii};
        curr_ann_type_idx = ann(ismember(ann_types, curr_ann_type)) - from_sample;

        % plot
        plot(t(curr_ann_type_idx), sig(curr_ann_type_idx),...
        'LineStyle', 'none', 'Marker', markers{marker_idx},...
        'MarkerEdgeColor', colors(color_idx,:),...
        'DisplayName', curr_ann_type);
        hold on;
        color_idx = mod(color_idx, length(colors))+1;
        marker_idx = mod(marker_idx, length(markers))+1;
    end
    legend();

end

end

