function [ sqi, tsqi ] = ecgsqi( ann1, ann2, ecg, fs, varargin)
%Computes bsqi [3]_ [4]_ to estimate the signal quality of an ECG signal.
%The bsqi index is computed over the whole ecg recording with a granularity
%specified by the user.
%
%:param ann1: vector of QRS annotations from a first peak detector (sample)
%:param ann2: vector of QRS annotations from a secon peak detector (sample)
%:param ecg: electrocardiogram time series (mV)
%:param fs: sampling frequency of the ecg (Hz)
%:param varargin: pass in name-value pairs to configure advanced options:
%
%   - agw: agreement window tolerated between annotations from the two
%     peak detectors in order for the two annotations to be considered in
%     agreement (in seconds) 
%   - sw: the size of the window on which the signal quality
%     is computed (in seconds). Default is 5 sec.
%   - rw: granularity at which the sqi is computed (in seconds). By
%     default the sqi is computed at every second.
%   - mw: window for a post-processing median smoothing (in
%     number of samples). By default there is no median post-processing.
%   - thrsqi: final sqi threshold. The signal will be considered of good
%     quality for all sqi value above this threshold (output sqi will be one
%     for these). Conversely the signal will be considered of bad quality for
%     all sqi value below this threshold (output sqi will be zero for these).
%   - plot: true/false whether to generate a plot. Defaults to true if no
%     output arguments were specified.
%
%:returns:
%
%   - sqi: signal quality time series (nu, in range 0-1)
%   - tsqi: time vector for the sqi vector (sec)
%
%Example: an ecg sample from the mitdb (physionet.org) is downloaded, preprocessed and 
%two peak detectors are ran (wjqrs and gqrs). The two sets of R-peak annotations are used to compare 
%the signal quality using the ecgsqi function.
%
%.. code-block:: matlab
%
%   download_wfdb_records('mitdb', '105', '.');
%   recordName = 'mitdb/105';
%   [~,ecg,Fs]=rdsamp(recordName,1);
%   bpfecg = bpfilt(ecg,Fs,5,45,[],0); % prefilter in range [5 - 45] Hz
%   anns_jqrs = wjqrs(bpfecg,Fs,0.3,0.250,10); % wjqrs peak detector
%   anns_gqrs = gqrs(recordName); % gqrs peak detector
%   anns_gqrs = double(anns_gqrs);
%
%   [ sqi, tsqi ] = ecgsqi( anns_jqrs', anns_gqrs, ecg, Fs, 'plot', true, 'mw', 1, 'sw', 5, 'rw', 1, 'agw', 0.050);


% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('ann1', @(x) isempty(x) || isvector(x));
p.addRequired('ann2', @(x) isempty(x) || isvector(x));
p.addRequired('ecg', @(x) isempty(x) || isvector(x));
p.addRequired('fs', @isnumeric);
p.addParameter('agw', nargout == 0, @isnumeric);
p.addParameter('sw', nargout == 0, @isscalar);
p.addParameter('rw', nargout == 0, @isscalar);
p.addParameter('mw', nargout == 0, @isscalar);
p.addParameter('thrsqi', nargout == 0, @isscalar);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(ann1, ann2, ecg, fs, varargin{:});
agw = p.Results.agw;
sw = p.Results.sw;
rw = p.Results.rw;
mw = p.Results.mw;
thrsqi = p.Results.thrsqi;
should_plot = p.Results.plot;

% convert annotations to time
ann1 = ann1 ./ fs;
ann2 = ann2 ./ fs;

% default values in case some of the optional parameters are not inputted
if agw==0; agw = 0.05; end
if sw==0; sw = 5; end
if rw==0; rw = 1; end
if mw==0; mw = 0; end

LG_REC = length(ecg)/fs;
xi1 = (0:rw:LG_REC)';

for w=1:numel(xi1)
    idx1_sel = ann1>w-1-floor(sw/2) & ann1<w-1+ceil(sw/2); % adjusting window size with local median heart rate
    fac = 70/median(60./diff(ann1(idx1_sel))); % adjusting window size with local median heart rate to ensure the estimation of the quality is always done on about the same number of beats
    
    idx1 = ann1>w-1-floor(fac*sw/2) & ann1<w-1+ceil(fac*sw/2);
    idx2 = ann2>w-1-floor(fac*sw/2) & ann2<w-1+ceil(fac*sw/2);
    
    refqrs = ann1(idx1);
    testqrs = ann2(idx2);
    
    [F1(w),~] = bsqi( refqrs*fs, testqrs*fs,agw,fs);
end

% NaN values indicate no ECG data for either lead - definitely bad quality
F1(isnan(F1)) = 0;

% Remove the non-relevant segments
idxRem = xi1 >= LG_REC+1; %+1 because the first value of the sqi is for time=0 sec
F1(idxRem) = [];
xi1(idxRem) = [];

%% Set what's good/what's bad quality
if ~isempty(thrsqi) && ~thrsqi==0
    F1 = F1>thrsqi;
end

%% Now smooth the SQI (F1)
F1=F1';

if mw~=0
    if size(F1,1) < (mw*2+1)
        F1smooth = F1;
    else
        F1smooth = nan(size(F1,1),2*mw+1);
        for k=1:mw
            % create a lagged version of F1
            F1smooth(:,k) = vertcat(ones(k,1),F1(1:end-k));

            % create a led version of F1
            F1smooth(:,k+mw) = vertcat(F1(k+1:end),ones(k,1));
        end
        F1smooth(:,end) = F1;
        
        F1smooth = median(F1smooth,2);
    end
else
    F1smooth = F1;
end

sqi = F1smooth;
tsqi = xi1;

if should_plot
    tm = 1/fs:1/fs:LG_REC;
    plot(tm,ecg);
    hold on; plot(ann1,ecg(round(ann1*fs)),'+r');
    hold on; plot(ann2,ecg(round(ann2*fs)),'+k');
    hold on; plot(tsqi,sqi,'LineWidth',2);
    legend('ecg','ann1','ann2');
    xlabel('Time (sec)');
    ylabel('Amplitude (mV)');
end

end
