function [ hrv_fd, pxx, f_lomb ] = hrv_freq( rri, tm_rri, varargin )
%HRV_FREQ Calcualte frequency-domain HRV metrics
%   Detailed explanation goes here

%% === Input

% Defaults
DEFAULT_F_MAX = 0.4; %Hz
DEFAULT_AR_ORDER = 24;
DEFAULT_METHOD = 'lomb';
%DEFAULT_WINDOW_MINUTES = 5;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('tm_rri',  @(x) isnumeric(x) && ~isscalar(x));

p.addParameter('f_max', DEFAULT_F_MAX, @isnumeric);
p.addParameter('ar_order', DEFAULT_AR_ORDER, @isnumeric);
p.addParameter('method', DEFAULT_METHOD, @ischar);
%p.addParameter('window_minutes', DEFAULT_WINDOW_MINUTES, @isnumeric);

% Get input
p.parse(rri, tm_rri, varargin{:});
f_max = p.Results.f_max;
ar_order = p.Results.ar_order;
method = p.Results.method;
%window_minutes = p.Results.window_minutes;

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

%% === Freq domain - Parametric

% resample to obtain uniformly sampled signal
fs_rri = ceil(2*f_max); %Hz
[rri_uni, tm_rri_uni] = resample(rri, tm_rri, fs_rri, 1, 1);

% Yule-Walker AR model
[pxx_ar, f_ar] = psd_yulewalker(rri_uni, fs_rri, ar_order);

%% === Freq domain - Non parametric

% lomb periodogram, evaluated at frequencies in f_ar
[pxx_lomb, f_lomb] = plomb(rri, tm_rri, f_ar);

%% === Metrics

% Select power spectrum type
if (strcmp(method, 'lomb') == 1)
    pxx = pxx_lomb;
else
    pxx = pxx_ar;
end

% Define freq bands
TOT_band = [min(f_lomb), f_max];
ULF_band = [min(f_lomb), 0.003];
VLF_band = [0.003, 0.04];
LF_band = [0.04, 0.15];
HF_band = [0.15, f_max];

% Calculate power in bands
hrv_fd = struct;
hrv_fd.TOT_PWR = bandpower(pxx, f_lomb, TOT_band,'psd');
hrv_fd.ULF_PWR = bandpower(pxx, f_lomb, ULF_band,'psd');
hrv_fd.VLF_PWR = bandpower(pxx, f_lomb, VLF_band,'psd');
hrv_fd.LF_PWR  = bandpower(pxx, f_lomb, LF_band, 'psd');
hrv_fd.HF_PWR  = bandpower(pxx, f_lomb, HF_band, 'psd');

end
