function qrs_pos = jqrs(ecg, fs, thr, rp, debug)
%Implementation of an energy based qrs detector [1]_. The algorithm is an
%adaptation of the popular Pan & Tompkins algorithm [2]_. The function assumes
%the input ecg is already pre-filtered i.e. bandpass filtered and that the
%power-line interference was removed. Of note, NaN should be represented by the
%value -32768 in the ecg (WFDB standard).
% 
%:param ecg: vector of ecg signal amplitude (mV)
%:param fs: sampling frequency (Hz)
%:param thr: threshold (nu)
%:param rp: refractory period (sec)
%:param debug: plot results (boolean)
%
%:returns:
%
%   - qrs_pos: position of the qrs (sample)
%
%
%Example: process an ecg recording from the mitdb (physionet.org). A bandpass filter is used to 
%preprocess the ECG in the range [4 - 45]Hz. Then the peak detector is ran with a refractory period of 250 ms 
%(a standard value for Human ECG analysis) is specified.
%
%
%.. code-block:: matlab
%
%   download_wfdb_records('mitdb', '105', '.');
%   [~,ecg,Fs]=rdsamp('mitdb/105',1);
%
%   bpfecg = bpfilt(ecg,Fs,4,45,[],0); % prefilter in range [4-45] Hz
%
%   qrs_pos = jqrs(bpfecg,Fs,0.4,0.250,1); % peak detection and plot
%
%
%.. [1] Behar, Joachim, Alistair Johnson, Gari D. Clifford, and Julien Oster.
%   "A comparison of single channel fetal ECG extraction methods." Annals of
%   biomedical engineering 42, no. 6 (2014): 1340-1353.
%
%.. [2] Pan, Jiapu, and Willis J. Tompkins. "A real-time QRS detection algorithm."
%   IEEE Trans. Biomed. Eng 32.3 (1985): 230-236.
%

INT_NB_COEFF = round(7*fs/256); % length is 30 for fs=256Hz  

% mathematical transformations
dffecg = diff(double(ecg')); % differenciate (one datapoint shorter)
sqrecg = dffecg.*dffecg; % square ecg
intecg = filter(ones(1,INT_NB_COEFF),1,sqrecg); % integrate
mdfint = intecg;

delay  = ceil(INT_NB_COEFF/2); 
mdfint = circshift(mdfint',[-delay,0]); % remove filter delay for scanning back through ecg

% thresholding
mdfint_temp = mdfint;
mdfint_temp(ecg==-32768)=[]; % exclude the NaN (encoded in WFDB format) from this count
xs = sort(mdfint_temp);
ind_xs = ceil(98/100*length(xs)); 
en_thres = xs(ind_xs);
poss_reg = mdfint>(thr*en_thres);

tm = 1/fs:1/fs:length(ecg)/fs;

% search back
SEARCH_BACK = 1;
if SEARCH_BACK
    indAboveThreshold = find(poss_reg); % indices of samples above threshold
    RRv = diff(tm(indAboveThreshold)); % compute RRv
    medRRv = median(RRv(RRv>0.01));
    indMissedBeat = find(RRv>1.5*medRRv); % missed a peak?
    % find interval onto which a beat might have been missed
    indStart = indAboveThreshold(indMissedBeat);
    indEnd = indAboveThreshold(indMissedBeat+1);

    for i=1:length(indStart)
        % look for a peak on this interval by lowering the energy threshold
        poss_reg(indStart(i):indEnd(i)) = mdfint(indStart(i):indEnd(i))>(0.25*thr*en_thres);
    end
end

% find indices into boudaries of each segment
left = find(diff([0 poss_reg'])==1); % remember to zero pad at start
right = find(diff([poss_reg' 0])==-1); % remember to zero pad at end

nb_s = length(left<30*fs);
loc  = zeros(1,nb_s);
for j=1:nb_s
    [~,loc(j)] = max(abs(ecg(left(j):right(j))));
    loc(j) = loc(j)-1+left(j);
end
sign = median(ecg(loc));


% loop through all possibilities 
compt=1;
NB_PEAKS = length(left);
maxval = zeros(1,NB_PEAKS);
maxloc = zeros(1,NB_PEAKS);
for i=1:NB_PEAKS
    if sign>0
        % if sign is positive then look for positive peaks
        [maxval(compt), maxloc(compt)] = max(ecg(left(i):right(i)));
    else
        % if sign is negative then look for negative peaks
        [maxval(compt), maxloc(compt)] = min(ecg(left(i):right(i)));
    end
    maxloc(compt) = maxloc(compt)-1+left(i); % add offset of present location

    % refractory period - has proved to improve results
    if compt>1
        if maxloc(compt)-maxloc(compt-1)<fs*rp && abs(maxval(compt))<abs(maxval(compt-1))
            maxloc(compt)=[]; maxval(compt)=[];
        elseif maxloc(compt)-maxloc(compt-1)<fs*rp && abs(maxval(compt))>=abs(maxval(compt-1))
            maxloc(compt-1)=[]; maxval(compt-1)=[];
        else
            compt=compt+1;
        end
    else
        % if first peak then increment
        compt=compt+1;
    end
end

qrs_pos = maxloc; % datapoints QRS positions

if debug
    figure;
    ax(1)=subplot(311);
    plot(tm,[mdfint;0]);
    hold on; plot(tm(left),mdfint(left),'og',tm(right),mdfint(right),'om'); 
     
    ax(2)=subplot(312);
    plot(tm,ecg);
    hold on; plot(tm(qrs_pos),ecg(qrs_pos),'+r');
    
    ax(3)=subplot(313);
    hold on; plot(tm(qrs_pos(1:end-1)),diff(qrs_pos)/fs,'+r');
    
    linkaxes(ax,'x');
end

end
