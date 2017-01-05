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
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(nni, tm_nni, varargin{:});
f_max = p.Results.f_max;
f_res = p.Results.f_res;
ar_order = p.Results.ar_order;
detrend_order = p.Results.detrend_order;
method = p.Results.method;
should_plot = p.Results.plot;

% Validate method
valid_methods = {'lomb', 'ar'};
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

% Calculate ratio of power in each band
hrv_fd.ULF_to_TOT = hrv_fd.ULF_PWR / hrv_fd.TOT_PWR;
hrv_fd.VLF_to_TOT = hrv_fd.VLF_PWR / hrv_fd.TOT_PWR;
hrv_fd.LF_to_TOT  = hrv_fd.LF_PWR  / hrv_fd.TOT_PWR;
hrv_fd.HF_to_TOT  = hrv_fd.HF_PWR  / hrv_fd.TOT_PWR;

% Calculate LF/HF ratio
hrv_fd.LF_to_HF  = hrv_fd.LF_PWR  / hrv_fd.HF_PWR;

%% === Display output if requested
if (should_plot)
    % Get the other type of spectrum so we can plot both
    if (strcmp(method, 'lomb') == 1)
        pxx_lomb = pxx;
        [~, pxx_ar, ~] = hrv_freq(nni, tm_nni, 'f_max', f_max, 'f_res', f_res, 'ar_order', ar_order, 'detrend_order', detrend_order, 'method', 'ar', 'plot', false);
    else
        pxx_ar = pxx;
        [~, pxx_lomb, ~] = hrv_freq(nni, tm_nni, 'f_max', f_max, 'f_res', f_res, 'detrend_order', detrend_order, 'method', 'lomb', 'plot', false);
    end

    figure;

    semilogy(f_axis, [pxx_lomb, pxx_ar]);
    grid on; hold on;
    xlabel('Frequency [hz]'); ylabel('Power Density [s^2/Hz]');

    % Vertical lines of frequency ranges
    lw = 3; ls = ':'; lc = 'black';
    xrange = [0,f_max*1.01];
    yrange = [1e-6, 1];
    line(VLF_band(1) * ones(1,2), yrange, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
    line(LF_band(1)  * ones(1,2), yrange, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
    line(HF_band(1)  * ones(1,2), yrange, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
    line(HF_band(2)  * ones(1,2), yrange, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
    xlim(xrange); ylim(yrange);

    % Names of frequency ranges
    text(VLF_band(1), yrange(2) * 0.5, ' VLF');
    text( LF_band(1), yrange(2) * 0.5,  ' LF');
    text( HF_band(1), yrange(2) * 0.5,  ' HF');

    legend('Lomb', 'Auto-regressive', 'Freq. Band Limit');
end

end
