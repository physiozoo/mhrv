function [ hrv_fd, pxx, f_axis ] = hrv_freq( nni, tm_nni, varargin )
%HRV_FREQ Calcualte frequency-domain HRV metrics
%   Detailed explanation goes here

%% === Input

% Defaults
DEFAULT_F_MAX = 0.4; % Hz
DEFAULT_F_RES = 1e-4; % Frequency resolution in Hz
DEFAULT_AR_ORDER = 24;
DEFAULT_DETREND_ORDER = 10;
DEFAULT_METHOD = 'lomb';
DEFAULT_WINDOW_MINUTES = 5;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('tm_rri',  @(x) isnumeric(x) && ~isscalar(x));

p.addParameter('f_max', DEFAULT_F_MAX, @isnumeric);
p.addParameter('f_res', DEFAULT_F_RES, @isnumeric);
p.addParameter('ar_order', DEFAULT_AR_ORDER, @isnumeric);
p.addParameter('detrend_order', DEFAULT_DETREND_ORDER, @isnumeric);
p.addParameter('method', DEFAULT_METHOD, @ischar);
p.addParameter('window_minutes', DEFAULT_WINDOW_MINUTES, @isnumeric);

% Get input
p.parse(nni, tm_nni, varargin{:});
f_max = p.Results.f_max;
f_res = p.Results.f_res;
ar_order = p.Results.ar_order;
detrend_order = p.Results.detrend_order;
method = p.Results.method;
window_minutes = p.Results.window_minutes;

% Validate method
valid_methods = {'lomb', 'ar', 'fft'};
switch(method)
    case valid_methods
        valid = true;
    otherwise
        valid = false;
end
if (valid == false)
    error(['invalid method: ''' method '''. Should be one of: ' strjoin(valid_methods, ',') '.']);
end

%% === Pre process

% Detrend and zero mean
nni = nni - mean(nni);
[poly, ~, poly_mu] = polyfit(tm_nni, nni, detrend_order);
rri_trend = polyval(poly, tm_nni, [], poly_mu);
nni = nni - rri_trend;

%% === NN intervals spectrum calculation

% Uniform sampling freq: Take about 5x more than f_max
fs_uni = f_res * ceil(f_max * 5 / f_res);

% Build a frequency axis as [0, fs_uni]
f_axis = (0 : f_res : fs_uni/2)';

% Select power spectrum type
if (strcmp(method, 'lomb') == 1)
    % lomb periodogram, evaluated at frequencies in f_axis
    [pxx, ~] = plomb(nni, tm_nni, f_axis);

else
    % resample to obtain uniformly sampled signal
    [nni_uni, ~] = resample(nni, tm_nni, fs_uni, 1, 1);

    % Yule-Walker AR model Spectrum, evaluated at frequencies in f_axis
    [pxx, ~] = psd_yulewalker(nni_uni, ar_order, f_axis);
end

%% === Metrics

% Define freq bands
TOT_band = [min(f_axis), f_max];
ULF_band = [min(f_axis), 0.003];
VLF_band = [0.003, 0.04];
LF_band = [0.04, 0.15];
HF_band = [0.15, f_max];

% Calculate power in bands
hrv_fd = struct;
hrv_fd.TOT_PWR = bandpower(pxx, f_axis, TOT_band,'psd');
hrv_fd.ULF_PWR = bandpower(pxx, f_axis, ULF_band,'psd');
hrv_fd.VLF_PWR = bandpower(pxx, f_axis, VLF_band,'psd');
hrv_fd.LF_PWR  = bandpower(pxx, f_axis, LF_band, 'psd');
hrv_fd.HF_PWR  = bandpower(pxx, f_axis, HF_band, 'psd');

end
