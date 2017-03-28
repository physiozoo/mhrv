function [ hrv_fd, pxx, f_axis ] = hrv_freq( nni, tnn, varargin )
%HRV_FREQ NN interval spectrum and frequency-domain HRV metrics
%   This function estimates the PSD (power spectral density) of a given nn-interval sequence, and
%   calculates the power in various frequency bands.
%   Inputs:
%       - nni: RR/NN intervals, in seconds.
%       - tnn: The correspondint times of the intervals, in seconds.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - methods: A cell array of strings containing names of methods to use to estimate the
%             spectrum. Supported methods are:
%               - 'lomb': Lomb-scargle periodogram.
%               - 'ar': Yule-Walker autoregressive model. Data will be resampled. No windowing will
%                       be performed for this method.
%               - 'welch': Welch's method (overlapping windows).
%               - 'fft': Simple fft-based periodogram, no overlap (also known as Bartlett's method).
%             In all cases, a Hamming window will be used on the samples. Data will not be resampled
%             for all methods except 'lomb', to 10*hf_band(2) (ten times the maximal frequency).
%             Default value is {'lomb', 'ar', 'welch'}.
%           - power_method: The method to use for calculating the power in each band. Can be any one
%             of the methods given in 'methods'. This also determines the spectrum that will be
%             returned from this function (pxx).
%             Default: First value in 'methods'.
%           - vlf_band: 2-element vector of frequencies in Hz defining the VLF band.
%             Default: [0.003, 0.04].
%           - lf_band: 2-element vector of frequencies in Hz defining the LF band.
%             Default: [0.04, 0.15].
%           - hf_band: 2-element vector of frequencies in Hz defining the HF band.
%             Default: [0.15, 0.4].
%           - window_minutes: Split intervals into windows of this length, calcualte the spectrum in
%             each window, and average them. A Hamming window will be also be applied to each window
%             after breaking the intervals into windows. Set to [] if you want to disable windowing.
%             Default: 5 minutes.
%           - detrend_order: Order of polynomial to fit to the data for detrending.
%             Default: 1 (i.e. linear detrending).
%           - ar_order: Order of the autoregressive model to use if 'ar' method is specific.
%             Default: 24.
%           - welch_overlap: Percentage of overlap between windows when using Welch's method.
%             Default: 50 percent.
%           - plot: true/false whether to generate plots. Defaults to true if no output arguments
%             were specified.
%   Outputs:
%       - hrv_fd: Struct containing the following HRV metrics:
%           - TOT_PWR: Total power in all three bands combined.
%           - VLF_PWR: Power in the VLF band.
%           - LF_PWR: Power in the LF band.
%           - HF_PWR: Power in the HF band.
%           - VLF_to_TOT: Ratio between VLF power and total power.
%           - LF_to_TOT: Ratio between LF power and total power.
%           - HF_to_TOT: Ratio between HF power and total power.
%           - LF_to_HF: Ratio between LF and HF power.
%       - pxx: Power spectrum. It's type is determined by the 'power_method' parameter.
%       - f_axis: Frequencies, in Hz, at which pxx was calculated.

%% Input
SUPPORTED_METHODS = {'lomb', 'ar', 'welch', 'fft'};

% Defaults
DEFAULT_METHODS = {'lomb', 'ar', 'welch'};
DEFAULT_VLF_BAND = [0.003, 0.04];
DEFAULT_LF_BAND  = [0.04,  0.15];
DEFAULT_HF_BAND  = [0.15,  0.4];
DEFAULT_WINDOW_MINUTES = 5;
DEFAULT_AR_ORDER = 24;
DEFAULT_WELCH_OVERLAP = 50; % percent
DEFAULT_DETREND_ORDER = 1;

% Define input
p = inputParser;
p.addRequired('nni', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('tnn',  @(x) isnumeric(x) && ~isscalar(x));

p.addParameter('methods', DEFAULT_METHODS, @(x) iscellstr(x) && ~isempty(x));
p.addParameter('power_method', [], @ischar);
p.addParameter('vlf_band', DEFAULT_VLF_BAND, @(x) isnumeric(2)&&length(x)==2&&x(2)>x(1));
p.addParameter('lf_band', DEFAULT_LF_BAND, @(x) isnumeric(2)&&length(x)==2&&x(2)>x(1));
p.addParameter('hf_band', DEFAULT_HF_BAND, @(x) isnumeric(2)&&length(x)==2&&x(2)>x(1));
p.addParameter('window_minutes', DEFAULT_WINDOW_MINUTES, @(x) isnumeric(x));
p.addParameter('detrend_order', DEFAULT_DETREND_ORDER, @(x) isnumeric(x)&&isscalar(x));
p.addParameter('ar_order', DEFAULT_AR_ORDER, @(x) isnumeric(x)&&isscalar(x));
p.addParameter('welch_overlap', DEFAULT_WELCH_OVERLAP, @(x) isnumeric(x)&&isscalar(x)&&x>=0&&x<100);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(nni, tnn, varargin{:});
methods = p.Results.methods;
power_method = p.Results.power_method;
vlf_band = p.Results.vlf_band;
lf_band = p.Results.lf_band;
hf_band = p.Results.hf_band;
window_minutes = p.Results.window_minutes;
detrend_order = p.Results.detrend_order;
ar_order = p.Results.ar_order;
welch_overlap = p.Results.welch_overlap;
should_plot = p.Results.plot;

% Validate methods
methods_validity = cellfun(@(method) any(strcmp(SUPPORTED_METHODS, method)), methods);
if (~all(methods_validity))
    invalid_methods = methods(~methods_validity);
    error('Invalid methods given: %s.', strjoin(invalid_methods, ', '));
end

% Validate power method
if (isempty(power_method))
    % Use the first provided method if power_method not provided
    power_method = methods{1};
elseif (~any(strcmp(SUPPORTED_METHODS, power_method)))
    error('Invalid power_method given: %s.', power_method);
elseif (~any(strcmp(methods, power_method)))
    error('No matching method provided for power_method %s', power_method);
end


% Set window_minutes to maximal value if requested
if (isempty(window_minutes))
    window_minutes = floor(tnn(end) / 60);
end

%% Preprocess

% Detrend and zero mean
nni = nni - mean(nni);
[poly, ~, poly_mu] = polyfit(tnn, nni, detrend_order);
nni_trend = polyval(poly, tnn, [], poly_mu);
nni = nni - nni_trend;

%% Initializations

t_win = 60 * window_minutes; % Window length in seconds
t_max = tnn(end);
f_min = vlf_band(1);
f_max = hf_band(2);
num_windows = floor(t_max / t_win);

% Sanity check
if (num_windows < 1)
    warning('window_minutes is shorter than the signal duration.');
    num_windows = 1;
    t_win = floor(t_max);
end

% Uniform sampling freq: Take 10x more than f_max
fs_uni = 10 * f_max; %Hz

% Uniform time axis
tnn_uni = tnn(1) : 1/fs_uni : tnn(end);
n_win_uni = t_win / (1/fs_uni);
num_windows_uni = floor(length(tnn_uni) / n_win_uni);

% Build a frequency axis. The best frequency resolution we can get is 1/t_win.
f_res  = 1 / t_win; % equivalent to fs_uni / n_win_uni 
f_axis = (0 : f_res : f_max)';

% Check Nyquist criterion: We need atleast 2*f_max*t_win samples in each window to resolve f_max.
if (n_win_uni <= 2*f_max*t_win)
    warning('Nyquist criterion not met for given window length and frequency bands');
end

% Initialize outputs
pxx_lomb  = []; calc_lomb  = false;
pxx_ar    = []; calc_ar    = false;
pxx_welch = []; calc_welch = false;
pxx_fft   = []; calc_fft   = false;

if (any(strcmp(methods, 'lomb')))
    pxx_lomb = zeros(length(f_axis), 1);
    calc_lomb = true;
end
if (any(strcmp(methods, 'ar')))
    pxx_ar = zeros(length(f_axis), 1);
    calc_ar = true;
end
if (any(strcmp(methods, 'welch')))
    pxx_welch = zeros(length(f_axis), 1);
    calc_welch = true;
end
if (any(strcmp(methods, 'fft')))
    pxx_fft = zeros(length(f_axis), 1);
    calc_fft = true;
end

% Interlopate nn-intervals if needed
if (calc_ar || calc_fft || calc_welch)
    nni_uni = interp1(tnn, nni, tnn_uni, 'spline')';
end

%% Lomb method
if (calc_lomb)
    for curr_win = 1:num_windows;
        curr_win_idx = (tnn >= t_win * (curr_win-1)) & (tnn < t_win * curr_win);

        nni_win = nni(curr_win_idx);
        tnn_win = tnn(curr_win_idx);
        
        n_win = length(nni_win);
        window_func = hamming(n_win);
        nni_win = nni_win .* window_func;
        
        % Check Nyquist criterion
        if (n_win <= 2*f_max*t_win)
            continue; % warning('Nyquist criterion not met in window %d, skipping', curr_win);
        end
        
        [pxx_lomb_win, ~] = plomb(nni_win, tnn_win, f_axis);
        pxx_lomb = pxx_lomb + pxx_lomb_win;
    end
    % Average
    pxx_lomb = pxx_lomb ./ num_windows;
end

%% AR Method
if (calc_ar)
    for curr_win = 1:num_windows_uni;
        curr_win_idx = ((curr_win - 1) * n_win_uni + 1) : (curr_win * n_win_uni);
        nni_win = nni_uni(curr_win_idx);

        % AR periodogram
        [pxx_ar_win, ~] = pyulear(nni_win, ar_order, f_axis, fs_uni);
        pxx_ar = pxx_ar + pxx_ar_win;
    end
    % Average
    pxx_ar = pxx_ar ./ num_windows_uni;
end

%% Welch Method
if (calc_welch)
    window = hamming(n_win_uni);
    welch_overlap_samples = floor(n_win_uni * welch_overlap / 100);
    [pxx_welch, ~] = pwelch(nni_uni, window, welch_overlap_samples, f_axis, fs_uni);
end

%% FFT method
if (calc_fft)
    window_func = hamming(n_win_uni);    
    for curr_win = 1:num_windows_uni;
        curr_win_idx = ((curr_win - 1) * n_win_uni + 1) : (curr_win * n_win_uni);
        nni_win = nni_uni(curr_win_idx);
        
        % FFT periodogram
        [pxx_fft_win, ~] = periodogram(nni_win, window_func, f_axis, fs_uni);
        pxx_fft = pxx_fft + pxx_fft_win;
    end
    % Average
    pxx_fft = pxx_fft ./ num_windows_uni;
end

%% Metrics

% Get the PSD for the requested power_method
pxx = eval(['pxx_' power_method]);

% Calculate power in bands
total_band = [f_min, f_axis(end)];
hrv_fd = struct;
hrv_fd.TOT_PWR = bandpower(pxx, f_axis, total_band,'psd');
hrv_fd.VLF_PWR = bandpower(pxx, f_axis, vlf_band,'psd');
hrv_fd.LF_PWR  = bandpower(pxx, f_axis, lf_band, 'psd');
hrv_fd.HF_PWR  = bandpower(pxx, f_axis, [hf_band(1) f_axis(end)], 'psd');

% Calculate ratio of power in each band
hrv_fd.VLF_to_TOT = hrv_fd.VLF_PWR / hrv_fd.TOT_PWR;
hrv_fd.LF_to_TOT  = hrv_fd.LF_PWR  / hrv_fd.TOT_PWR;
hrv_fd.HF_to_TOT  = hrv_fd.HF_PWR  / hrv_fd.TOT_PWR;

% Calculate LF/HF ratio
hrv_fd.LF_to_HF  = hrv_fd.LF_PWR  / hrv_fd.HF_PWR;

%% Display output if requested
if (should_plot)
    figure;
    legend_entries = {};
    
    if (calc_lomb)
        semilogy(f_axis, pxx_lomb); grid on; hold on;
        legend_entries{end+1} = sprintf('Lomb (t_{win}=%dm, n_{win}=%d)', window_minutes, num_windows);
    end
    if (calc_ar)
        semilogy(f_axis, pxx_ar); grid on; hold on;
        legend_entries{end+1} = sprintf('AR (order=%d)', ar_order);
    end
    if (calc_welch)
        semilogy(f_axis, pxx_welch); grid on; hold on;
        legend_entries{end+1} = sprintf('Welch (t_{win}=%dm, %d%% ovl.)', window_minutes, welch_overlap);
    end
    if (calc_fft)
        semilogy(f_axis, pxx_fft); grid on; hold on;
        legend_entries{end+1} = sprintf('FFT (twin=%dm, nwin=%d)', window_minutes, num_windows);
    end

    % Vertical lines of frequency ranges
    lw = 3; ls = ':'; lc = 'black';
    xrange = [0,f_max*1.01];
    yrange = [1e-4, 1e0];
    line(vlf_band(1) * ones(1,2), yrange, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
    line(lf_band(1)  * ones(1,2), yrange, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
    line(hf_band(1)  * ones(1,2), yrange, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
    line(hf_band(2)  * ones(1,2), yrange, 'LineStyle', ls, 'Color', lc, 'LineWidth', lw);
    xlim(xrange); ylim(yrange);

    % Names of frequency ranges
    text(vlf_band(1), yrange(2) * 0.5, ' VLF');
    text( lf_band(1), yrange(2) * 0.5,  ' LF');
    text( hf_band(1), yrange(2) * 0.5,  ' HF');

    legend_entries{end+1} = 'Freq. Band Limit';
    legend(legend_entries);
    xlabel('Frequency [hz]'); ylabel('Log Power Density [s^2/Hz]');
end

end
