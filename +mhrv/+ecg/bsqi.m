function [ F1, IndMatch, meanDist ] = bsqi( refqrs, testqrs, agw, fs)
%This algorithm can be used to estimate the signal quality of a single channel
%electrocardiogram [3]_ [4]_. It compares the agreement between the R-peak
%annotations (ann1 and ann2) made by two different R-peak detectors. If the two
%detectors agree locally then the signal quality (sqi) is good and if they
%disagree then it is likely because of some uderlying artifacts/noise in the
%signal. The limitation of this method is that when one of the two detectors
%fails for whatever reason other than the presence of noise then the quality
%will be zero.
%
%:param refqrs: vector of QRS annotations from a first peak detector (in
%   seconds)
%:param testqrs: vector of QRS annotations from a secon peak detector (in
%   seconds)
%:param agw: agreement window (sec)
%:param fs: sampling frequency (Hz)
%
%:returns:
%
%   - F1: signal quality measure (nu)
%   - IndMatch: indices of matching peaks (nu)
%   - meanDist: mean distance between matching refqrs and testqrs peaks (sec)
%
%
%Example: Comparing ``gqrs`` to ``wjqrs`` on a record from ``mitdb``.
%
%.. code-block:: matlab
%
%   download_wfdb_records('mitdb', '105', '.');
%   [tm,ecg,Fs]=rdsamp('mitdb/105',1,'from',450000,'to',480000);
%   bpfecg = bpfilt(ecg,Fs,5,45,[],0); % prefilter in range [5 - 45] Hz
%   anns_jqrs = wjqrs(bpfecg,Fs,0.3,0.250,10); % wjqrs peak detector
%   anns_gqrs = gqrs('mitdb/105','from',450000,'to',480000); % gqrs peak detector
%   anns_gqrs = double(anns_gqrs);
%
%   [F1,~] = bsqi( anns_jqrs', anns_gqrs,0.050,Fs);
%   plot(tm,ecg);
%   hold on; plot(tm(anns_jqrs),ecg(anns_jqrs),'+r');
%   hold on; plot(tm(anns_gqrs),ecg(anns_gqrs),'+k');
%   legend(['ecg with quality ' num2str(F1)],'wjqrs','gqrs');
%
%
%.. [3] Behar, J., Oster, J., Li, Q., & Clifford, G. D. (2013). ECG signal
%   quality during arrhythmia and its application to false alarm reduction.  IEEE
%   transactions on biomedical engineering, 60(6), 1660-1666.
%
%.. [4] Johnson, Alistair EW, Joachim Behar, Fernando Andreotti,
%   Gari D. Clifford, and Julien Oster.  "Multimodal heart beat detection using
%   signal quality indices." Physiological measurement 36, no. 8 (2015): 1665.


%managing inputs
if nargin<3; agw=0.05; end;
if nargin<4; fs=250; end;
agw = agw * fs;

if ~isempty(refqrs) && ~isempty(testqrs)
    NB_REF  = length(refqrs);
    NB_TEST = length(testqrs);
    %core function
    [IndMatch,Dist] = dsearchn(refqrs,testqrs); % closest ref for each point in test qrs
    IndMatchInWindow = IndMatch(Dist<agw); % keep only the ones within a certain window
    NB_MATCH_UNIQUE = length(unique(IndMatchInWindow)); % how many unique matching
    TP = NB_MATCH_UNIQUE; % number of identified ref QRS
    FN = NB_REF-TP; % number of missed ref QRS
    FP = NB_TEST-TP; % how many extra detection?
    Se  = TP/(TP+FN);
    PPV = TP/(FP+TP);
    F1 = 2*Se*PPV/(Se+PPV); % accuracy measure
    
    
    %get mean distance between ref and testqrs
    [~ ,ind_plop] = unique(IndMatchInWindow);
    Dist_thres = find(Dist<agw);
    meanDist = mean(Dist(Dist_thres(ind_plop)))./fs;
    
else
    F1 = 0;
    IndMatch = [];
    meanDist = fs;
end
end
