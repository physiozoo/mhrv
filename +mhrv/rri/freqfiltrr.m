function [ rri_out, trr_out ] = freqfiltrr( rri, fc, varargin )
%Performs frequency-band filtering of RR intervals.  This function can apply
%a low-pass or high-pass filter to an RR interval time series.
%
%:param rri: RR-intervals values in seconds.
%:param fc:  Filter cutoff frequency, in Hz.
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - resamp_freq: Frequency to resample the RR-intervals at before filtering.
%     Must be at least twich the maximal frequency in the signal. Default: 5 Hz.
%   - forder: Order (length in samples) of the filter to use. Default: 100.
%   - ftype: A string, either 'low' or 'high', specifying the type of filter to
%     apply.
%   - plot: true/false whether to generate a plot. Defaults to true if no
%     output arguments were specified.
%
%:returns:
%
%   - rri_out: RR intervals after filtering.
%   - trr_out: Times of filtered RR intervals, in seconds.

%% Input

% Defaults
DEFAULT_RESAMPLING_FREQ = 5; % Hz
DEFAULT_FILTER_ORDER = 100;
DEFAULT_FILTER_TYPE = 'low'; % low/high

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('fc', @(x) isnumeric(x) && ~isempty(x) && length(x) <= 2);
p.addParameter('resamp_freq', DEFAULT_RESAMPLING_FREQ, @isscalar);
p.addParameter('forder', DEFAULT_FILTER_ORDER, @isscalar);
p.addParameter('ftype', DEFAULT_FILTER_TYPE, @(x) any(cellfun(@(y) strcmp(y,x), {'low', 'high', 'exp'})));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rri, fc, varargin{:});
resamp_freq = p.Results.resamp_freq;
forder = p.Results.forder;
ftype = p.Results.ftype;
should_plot = p.Results.plot;

%% Resample

% Make sure there are no zero-length intervals, becasue we can't resample that
rri(rri == 0) = [];

% Create time axis
rri = rri(:);
trr = [0; cumsum(rri(1:end-1))];

trr_resamp = (trr(1):(1/resamp_freq):trr(end))';
rri_resamp = interp1(trr, rri, trr_resamp, 'spline');


%% Create and apply filter
if strcmpi(ftype, 'low') || strcmpi(ftype, 'high')
    % Normalized cutoff frequency
    nyq_freq = resamp_freq/2;
    wc = fc ./ nyq_freq;

    % Filter coefficients
    b = fir1(forder, wc, ftype);

    rri_filt = filter(b, 1, rri_resamp);

    if strcmpi(ftype, 'high')
        % Add back DC in case of HPF, because we want physiological RR values
        rri_filt = rri_filt + mean(rri);
    end
else
    tfmax = 1/fc;
    alpha = -log(1e-3)/tfmax;
    b = exp(-alpha * [0:(1/resamp_freq):tfmax]);
    b = b/sum(b);
    rri_filt = filter(b, 1, rri_resamp);
end

%% Remove filter delay

% Filter delay (delay in samples is half the filter order)
delay_sec = ((length(b)-1)/2) / resamp_freq;
trr_filt = trr_resamp - delay_sec;
post_delay_idx = trr_filt > delay_sec;
rri_filt = rri_filt(post_delay_idx);
trr_filt = trr_filt(post_delay_idx);

%% Downsample at original times

trr_downsample = trr(trr >= trr_filt(1) & trr <= trr_filt(end));
rri_downsample = interp1(trr_filt, rri_filt, trr_downsample, 'spline');

% Assign output
rri_out = rri_downsample;
trr_out = trr_downsample;

%% Plot
if should_plot
    figure;
    plot(trr, rri, trr_downsample, rri_downsample);
    grid on;
    xlabel('time (sec)'); ylabel('RR intervals');
    legend('Original', 'Filtered');
    
    figure;
    freqz(b,1, 1024, resamp_freq);
end
end

