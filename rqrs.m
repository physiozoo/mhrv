function [ qrs ] = rqrs( recName, varargin )
%RQRS R-peak detection in ECG signals, based on 'gqrs'
%   Detailed explanation goes here

%% === Input

% Defaults
DEFAULT_N = [];
DEFAULT_N0 = 1;
DEFAULT_OUT_EXT = 'rqrs';
DEFAULT_ECG_COL = [];
DEFAULT_CONFIG = '';

% Define input
p = inputParser;
p.addRequired('recName', @isstr);
p.addParameter('N', DEFAULT_N, @isnumeric);
p.addParameter('N0', DEFAULT_N0, @isnumeric);
p.addParameter('out_ext', DEFAULT_OUT_EXT, @isstr);
p.addParameter('ecg_col', DEFAULT_ECG_COL, @isnumeric);
p.addParameter('config', DEFAULT_CONFIG, @isstr);

% Get input
p.parse(recName, varargin{:});
N = p.Results.N;
N0 = p.Results.N0;
out_ext = p.Results.out_ext;
ecg_col = p.Results.ecg_col;
config = p.Results.config;

%% === Input validation

% Make sure record file exists
if (~exist([recName '.dat'], 'file') || ~exist([recName '.hea'], 'file'))
    error('Record data or header file not found: %s', recName);
end

% Make sure config file exists (if specified)
if (~isempty(config) && ~exist(config, 'file'))
    error('Config file not found: %s', config);
end

%% === Find ECG signal index if it wasn't specified
if (isempty(ecg_col))
    ecg_col = get_signal_channel(recName, 'ecg');
    if (isempty(ecg_col)); error('can''t find ECG signal in record'); end;
end

% Subtract one from all indices since wfdb is zero-based
ecg_col = ecg_col-1;
N0 = N0-1;
if (~isempty(N)); N = N-1; end

%% === Create commandline arguments

cmdline = sprintf('gqrs -r %s -s %d -f s%d -o %s', recName, ecg_col, N0, out_ext);
if (~isempty(N))
    cmdline = sprintf('%s -t s%d', cmdline, N);
end
if (~isempty(config))
        cmdline = sprintf('%s -c %s', cmdline, config);
end

%% === Run gqrs
[retval, output] = system(cmdline);
if(retval ~= 0)
    error('gqrs error: %s', output);
end

%% === Parse annotation

% For now use the wfdb-app-toolbox wrapper
try
    qrs = rdann(recName, out_ext, [], []);
catch
    warning('%s: Failed to read gqrs results', recName);
    qrs = [];
end

% Delete the annotation file
delete([recName, '.', out_ext]);
end

