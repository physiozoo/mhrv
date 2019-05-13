function rri_detrended = detrendrr( rri, lambda, Fs, varargin )
%A detrending method [4]_ for the RR intervals. This is used when analysing RR
%interval time series over a long window thus where the stationarity assumption
%is not valid anymore. Of note: a number of HRV methods such as the
%fragmentation measures and the DFA measures do not assume the intervals to be
%stationary. Thus usage of this detrending tool is specific to what HRV
%measures are being studied.  Detrending will also likely affect the low
%frequency fluctuation information contained in the VLF band.
%
%:param rri: Vector of RR-interval dirations (seconds)
%:param lambda: lambda (lambda=10 for Human)
%:param Fs: the sampling frequency of the original ECG signal (Hz)
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - plot: true/false whether to generate a plot. Defaults to true if no
%     output arguments were specified (boolean).
%
%:returns:
%   - rri_detrended: detrended rri interval (seconds)
%
%
%Example: process an ecg recording sampled at 1000 Hz and
%specifying a refractory period of 250 ms (a standard value for Human ECG)
%and with a threshold of 0.5.
%
%.. code-block:: matlab
%
%   recordName = 'mitdb/105';
%   [ecg,fs,~] = rdsamp(recordName,1);
%   bpfecg = bpfilt(ecg,fs,5,45,[],0); % prefilter in range [5-45] Hz
%   anns_jqrs = wjqrs(bpfecg,fs,0.3,0.250,10); % jqrs running on each segment of 10 sec length
%   z = diff(anns_jqrs)/fs; % get the RR intervals
%
%   nni_detrend = detrend_nn(z',10,'Fs',Fs ,'plot',true); % detrend and plot
%
%
%.. [4]
%   Tarvainen, Mika P., Perttu O. Ranta-Aho, and Pasi A. Karjalainen. "An
%   advanced detrending method with application to HRV analysis." IEEE
%   Transactions on Biomedical Engineering 49.2 (2002): 172-175.
%

%% === Input
% Defaults
%DEFAULT_LAMBDA = 10; % FIXME: this parameter needs to be tuned for the different mammals (?)
                     % in any case this will need to be included in the
                     % configuration
% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isempty(x) || isvector(x));
p.addRequired('lambda', @isscalar);
p.addRequired('Fs', @isscalar);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rri, lambda, Fs, varargin{:});
should_plot = p.Results.plot;

% Convert to milliseconds
rri = rri * 1000;

% Compute detrend
T = length(rri);
I = speye(T);
D2 = spdiags(ones(T-2,1)*[1 -2 1],[0:2],T-2,T);
rri_detrended = (I-inv(I+lambda^2*D2'*D2))*rri;
rri_detrended = rri_detrended/1000; % back to sec
rri = rri/1000; % back to sec

% Plot
plot_data.name = 'Detrending rri';
plot_data.rri = rri;

if should_plot
    figure('Name', plot_data.name);
    tm = cumsum(rri)/Fs;
    plot(tm,rri);
    hold on; plot(tm,rri-rri_detrended,'r');
    xlabel('Time (sec)');
    ylabel('rri (sec)');
    legend('rri','detrended rri');
    box off;
end


end
