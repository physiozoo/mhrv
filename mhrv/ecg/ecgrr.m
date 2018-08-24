function [ rri, trr, plot_data ] = ecgrr( rec_name, varargin )
%ECGRR Calculate an RR-interval time series from PhysioNet ECG data.
% Detects QRS in a given sigal and calculates the RR intervals.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - ann_ext: Specify an annotation file extention to use instead of loading the record
%            itself (.dat file). If provided, RR intervals will be loaded from the annotation file
%            instead of from the ECG. Default: empty (don't use annotation).
%           - ecg_channel: Number of ecg signal in the record (default [], i.e. auto-detect signal).
%           - from: Number of first sample to start detecting from (default 1)
%           - to: Number of last sample to detect until (default [], i.e. end of signal)
%           - plot: true/false whether to generate a plot. Defaults to true if no output arguments
%                   were specified.
%   Outputs:
%       - rri: RR-intervals values in seconds.
%       - trr: RR-interval times in seconds.
%

%% Input
% Defaults
DEFAULT_ANN_EXT = '';
DEFAULT_FROM_SAMPLE = 1;
DEFAULT_TO_SAMPLE = [];
DEFAULT_ECG_CHANNEL = [];

% Define input
p = inputParser;
p.addRequired('rec_name');
p.addParameter('header_info', [], @(x) isempty(x) || isstruct(x));
p.addParameter('ann_ext', DEFAULT_ANN_EXT, @(x) ischar(x));
p.addParameter('from', DEFAULT_FROM_SAMPLE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('to', DEFAULT_TO_SAMPLE, @(x) isnumeric(x) && (isscalar(x)||isempty(x)));
p.addParameter('ecg_channel', DEFAULT_ECG_CHANNEL, @(x) isempty(x)||(isnumeric(x) && isscalar(x)));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
header_info = p.Results.header_info;
ann_ext = p.Results.ann_ext;
from_sample = p.Results.from;
to_sample = p.Results.to;
ecg_channel = p.Results.ecg_channel;
should_plot = p.Results.plot;

% Validate record
if isempty(ann_ext)
    if ~isrecord(rec_name)
        error('Can''t find data file for record %s', ann_ext, rec_name);
    end
else
    if ~isrecord(rec_name, ann_ext)
        error('Can''t find annotation %s for record %s', ann_ext, rec_name);
    end
end

% Validate header info
if isempty(header_info)
    header_info = wfdb_header(rec_name);
elseif ~strcmp(rec_name, header_info.rec_name)
    error('Provided header_info was for a different record');
end

%% QRS detection
% Make sure we have an ECG channel in the record
Fs = header_info.Fs;
if isempty(ecg_channel)
    default_ecg_channel = get_signal_channel(rec_name, 'header_info', header_info);
    if isempty(default_ecg_channel) && isempty(ann_ext)
        error('No ECG channel found in record %s', rec_name);
    else
        ecg_channel = default_ecg_channel;
    end
end

% If we have an annotation extension, load annotations instead of ECG data.
if ~isempty(ann_ext)
    % Load annotations: indexes of normal beats
    ann = rdann( rec_name, ann_ext, 'from', from_sample, 'to', to_sample, 'ann_types', '"N"');

    % Make sure we got annotations
    if (isempty(ann))
        rri=[]; trr=[]; plot_data = struct;
        return;
    end

    % Convert indices to double-precision to prevent rounding to integers
    % in the following calculations
    ann = double(ann);

    % Calcualte the RR intervals and their absolute time in the signal based on the
    % beat indices and the sampling frequency of the record.
    start_time = (ann(1) - 1) * (1/Fs);
    rri = diff(ann) .* (1/Fs);
    trr = [0; cumsum(rri(1:end-1))] + start_time;

    % Create an empty plot data. We don't have the signal to plot in this case.
    plot_data = struct;
    return;
else
    % Use rqrs to find QRS complex locations
    [qrs, tm, sig, ~] = rqrs(rec_name, 'header_info', header_info,...
        'ecg_channel', ecg_channel, ...
        'from', from_sample, 'to', to_sample);

    % Make sure we got detections before continuing (it's possible to get none in e.g. very noisy
    % parts of a signal)
    if (isempty(qrs))
        rri=[]; trr=[]; plot_data = struct;
        return;
    end

    % RR-intervals are the time-difference between R-Peaks
    rri = diff(tm(qrs));
    trr = tm(qrs(1:end-1));
end

%% Plot if no output args or if requested
plot_data.name = 'ECG R-peaks';
plot_data.tm = tm;
plot_data.sig = sig;
plot_data.qrs = qrs;

if (should_plot)
    figure('Name', plot_data.name);
    plot_ecgrr(gca, plot_data);
end
end

