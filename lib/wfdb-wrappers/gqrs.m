function [ qrs, outliers ] = gqrs( rec_name, varargin )
%GQRS Wrapper for WFDB's 'gqrs' and 'gqpost' tools.
%   Finds the onset of QRS complexes in ECG signals given in PhysioNet format and returns them as a
%   MATLAB vector.
%   Inputs:
%       - rec_name: Path and name of a wfdb record's files e.g. db/mitdb/100 if the record files (both
%                   100.dat and 100.hea) are in a folder named 'db/mitdb' relative to MATLABs pwd.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - 'ecg_col': Number of ecg signal in the record (default [], i.e. auto-detect signal).
%           - 'gqconf': Path to a gqrs config file to use. This allows adapting the algorithm for
%                       different signal and/or animal types (default is '', i.e. no config file).
%           - 'gqpost': Whether to run the 'gqpost' tool to find erroneous detections (default
%                       false).
%           - 'N0': Number of first sample to start detecting from (default 1)
%           - 'N': Number of last sample to detect until (default [], i.e. end of signal)
%
%   Output:
%       - qrs: Vector of sample numbers where the an onset of a QRS complex was found.
%       - outliers: Vector of sample numbers which were marked by gqpost as suspected false
%                   detections.
%   If no output variables are given to the function call, the detected ECG signal and QRS complexes
%   will be plotted in a new figure.

%% === Input

% Defaults
DEFAULT_N = [];
DEFAULT_N0 = 1;
DEFAULT_OUT_EXT = 'qrs';
DEFAULT_ECG_COL = [];
DEFAULT_CONFIG = '';
DEFAULT_GQPOST = false;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('N', DEFAULT_N, @isnumeric);
p.addParameter('N0', DEFAULT_N0, @isnumeric);
p.addParameter('out_ext', DEFAULT_OUT_EXT, @isstr);
p.addParameter('ecg_col', DEFAULT_ECG_COL, @isnumeric);
p.addParameter('gqconf', DEFAULT_CONFIG, @isstr);
p.addParameter('gqpost', DEFAULT_GQPOST, @islogical);

% Get input
p.parse(rec_name, varargin{:});
N = p.Results.N;
N0 = p.Results.N0;
out_ext = p.Results.out_ext;
ecg_col = p.Results.ecg_col;
gqconf = p.Results.gqconf;
gqpost = p.Results.gqpost;

%% === Input validation

% Make sure config file exists (if specified)
if (~isempty(gqconf) && ~exist(gqconf, 'file'))
    error('Config file not found: %s', gqconf);
end

%% === Find ECG signal index if it wasn't specified
if (isempty(ecg_col))
    ecg_col = get_signal_channel(rec_name);
    if (isempty(ecg_col)); error('can''t find ECG signal in record'); end;
end

% Subtract one from all indices since wfdb is zero-based
ecg_col = ecg_col-1;
N0 = N0-1;
if (~isempty(N)); N = N-1; end

%% === Create commandline arguments

% commanline for gqrs
gqrs_path = get_wfdb_tool_path('gqrs');
cmdline = sprintf('%s -r %s -s %d -f s%d -o %s', gqrs_path, rec_name, ecg_col, N0, out_ext);
if (~isempty(N))
    cmdline = sprintf('%s -t s%d', cmdline, N);
end
if (~isempty(gqconf))
        cmdline = sprintf('%s -c %s', cmdline, gqconf);
end

% append command for gqpost (use '&&' to make it conditional on gqrs's success)
if (gqpost)
    gqpost_cmdline = regexprep(cmdline, 'gqrs ', 'gqpost '); % replace 'gqrs' with 'gqpost'
    gqpost_cmdline = regexprep(gqpost_cmdline, ' -[so] \S+', ''); % remove '-s X'/'-o X' flags but keep others
    cmdline = [cmdline, ' && ', gqpost_cmdline];
end

%% === Run gqrs
[retval, output] = jsystem(cmdline);
if(retval ~= 0)
    error('gqrs error: %s', output);
end

%% === Parse annotation
try
    qrs = rdann(rec_name, out_ext);
    if (gqpost)
        outliers = rdann(rec_name, 'gqp', 'ann_types', '"|"');
    else
        outliers = [];
    end
catch e
    warning('%s: Failed to read gqrs results - %s', rec_name, e.message);
    qrs = [];
end

% Delete the annotation file
delete([rec_name, '.', out_ext]);
if (gqpost); delete([rec_name, '.', 'gqp']); end

% Plot if no output arguments
if (nargout == 0)
    ecg_col = get_signal_channel(rec_name);
    [tm, sig, ~] = rdsamp(rec_name, ecg_col);
    figure;
    plot(tm, sig); hold on; grid on;
    plot(tm(qrs), sig(qrs,1), 'rx');
    
    if (~isempty(outliers))
        plot(tm(outliers), sig(outliers,1), 'ko');
        legend('signal', 'qrs detections', 'suspected outliers');
    else
        legend('signal', 'qrs detections');
    end
end
end