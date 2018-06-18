function [ qrs, outliers ] = gqrs( rec_name, varargin )
%GQRS Wrapper for WFDB's 'gqrs' and 'gqpost' tools.
%   Finds the onset of QRS complexes in ECG signals given in PhysioNet format and returns them as a
%   MATLAB vector.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - 'ecg_channel': Number of ecg signal in the record (default [], i.e. auto-detect signal).
%           - 'gqconf': Filename or Path to a gqrs config file to use. This allows adapting the
%                       algorithm for different signal and/or animal types (default is '', i.e. no
%                       config file). Note that if only a filename is provided, 'gqrs' will attempt
%                       to find the gqconf file on the MATLAB path.
%           - 'gqpost': Whether to run the 'gqpost' tool to find erroneous detections (default
%                       false).
%           - 'from': Number of first sample to start detecting from (default 1)
%           - 'to': Number of last sample to detect until (default [], i.e. end of signal)
%
%   Output:
%       - qrs: Vector of sample numbers where the an onset of a QRS complex was found.
%       - outliers: Vector of sample numbers which were marked by gqpost as suspected false
%                   detections.
%   If no output variables are given to the function call, the detected ECG signal and QRS complexes
%   will be plotted in a new figure.

%% === Input

% Defaults
DEFAULT_TO_SAMPLE = [];
DEFAULT_FROM_SAMPLE = 1;
DEFAULT_ECG_CHANNEL = [];
DEFAULT_CONFIG = '';
DEFAULT_GQPOST = false;

% Define input
p = inputParser;
p.addRequired('rec_name', @isrecord);
p.addParameter('from', DEFAULT_FROM_SAMPLE, @(x) isnumeric(x) && isscalar(x));
p.addParameter('to', DEFAULT_TO_SAMPLE, @(x) isnumeric(x) && (isscalar(x)||isempty(x)));
p.addParameter('ecg_channel', DEFAULT_ECG_CHANNEL, @isnumeric);
p.addParameter('gqconf', DEFAULT_CONFIG, @isstr);
p.addParameter('gqpost', DEFAULT_GQPOST, @islogical);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
from_sample = p.Results.from;
to_sample = p.Results.to;
ecg_channel = p.Results.ecg_channel;
gqconf = p.Results.gqconf;
gqpost = p.Results.gqpost;
should_plot = p.Results.plot;

% Create a random suffix for the output file extensions (this prevents collisions when running on
% the same file in parallel)
suffix = num2str(randi(999999));
out_ext = ['qrs' suffix];
out_ext_gqp = ['gqp' suffix];

%% === Input validation

% Make sure config file exists (if specified)
if ~isempty(gqconf)
    % Try to find the config file on the MATLAB path. If it doesn't exist, treat it as a relative path.
    w = which(gqconf);
    if ~isempty(w)
        gqconf = w;
    elseif exist(gqconf, 'file')
        gqconf = GetFullPath(gqconf);
    else
        error('Config file not found: %s', gqconf);
    end
end

%% === Find ECG signal index if it wasn't specified
if isempty(ecg_channel)
    ecg_channel = get_signal_channel(rec_name);
    if (isempty(ecg_channel)); error('can''t find ECG signal in record'); end;
end

%% === Create commandline arguments
[rec_path, rec_filename, ~] = file_parts(rec_name);

% commanline for gqrs
gqrs_path = get_wfdb_tool_path('gqrs');
cmdline = sprintf('%s -r %s -s %d -f s%d -o %s', gqrs_path, rec_filename, ecg_channel-1, from_sample-1, out_ext);
if (~isempty(to_sample))
    cmdline = sprintf('%s -t s%d', cmdline, to_sample-1);
end
if (~isempty(gqconf))
        cmdline = sprintf('%s -c %s', cmdline, gqconf);
end

% append command for gqpost (use '&&' to make it conditional on gqrs's success)
if (gqpost)
    gqpost_path = get_wfdb_tool_path('gqpost');
    gqpost_cmdline = strrep(cmdline, gqrs_path, gqpost_path); % replace 'gqrs' executable name with 'gqpost'
    gqpost_cmdline = regexprep(gqpost_cmdline, ' -[so] \S+', ''); % remove '-s X'/'-o X' flags but keep others
    gqpost_cmdline = sprintf('%s -a %s -o %s', gqpost_cmdline, out_ext, out_ext_gqp); % add output ext
    cmdline = [cmdline, ' && ', gqpost_cmdline];
end

%% === Run gqrs
[retval, output, stderr] = jsystem(cmdline, [], rec_path);
if(retval ~= 0)
    error('gqrs error: %s\n%s', stderr, output);
end

%% === Parse annotation
try
    qrs = rdann(rec_name, out_ext);
    if (gqpost)
        outliers = rdann(rec_name, out_ext_gqp, 'ann_types', '"|"');
    else
        outliers = [];
    end

    % it's possible for some detections to be outside the range we requested, so make sure they are
    to_sample_scalar = to_sample;
    if (isempty(to_sample_scalar)); to_sample_scalar = Inf; end;
    qrs = qrs(qrs >= from_sample & qrs <= to_sample_scalar) - from_sample + 1;
    outliers = outliers(outliers >= from_sample & outliers <= to_sample_scalar) - from_sample + 1;
catch e
    warning('%s: Failed to read gqrs results - %s', rec_name, e.message);
    qrs = [];
end

% Delete the annotation file
delete([rec_name, '.', out_ext]);
if (gqpost); delete([rec_name, '.', out_ext_gqp]); end

%% Plot
if (should_plot)
    [tm, sig, ~] = rdsamp(rec_name, ecg_channel, 'from', from_sample, 'to', to_sample);
    figure;
    plot(tm, sig); hold on; grid on;
    plot(tm(qrs), sig(qrs,1), 'rx', 'MarkerSize', 6);
    xlabel('time (s)'); ylabel('ECG (mV)');
    
    if (~isempty(outliers))
        plot(tm(outliers), sig(outliers,1), 'ko', 'MarkerSize', 6);
        legend('signal', 'qrs detections', 'suspected outliers');
    else
        legend('signal', 'qrs detections');
    end
end
end
