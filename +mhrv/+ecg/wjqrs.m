function qrs = wjqrs(ecg, fs, thres, rp, ws)
%This function [1]_ is used to run the jqrs peak detector using a sliding
%(non-overlapping) window. This is usefull in the cases where the signal
%contains important artefacts which could bias the jqrs threshold evaluation
%or if the amplitude of the ecg is changing substantially over long recordings
%because of the position of the electrodes move for example.  In these
%instances the adaptation of the energy threshold is useful.
%
%:param ecg: ecg signal (mV)
%:param fs: sampling frequency (Hz)
%:param thres: threshold to be used in the P&T algorithm(nu)
%:param rp: refractory period (sec)
%:param ws: window size (sec)
% 
%:returns:
%
%   - qrs: qrs location in nb samples (ms)
%
%Example: perform peak detection on an ecg recording from the mitdb (physionet.org), 
%A refractory period of 250 ms (a standard value for Human ECG)
%and a threshold of 0.3 are used.
%
%.. code-block:: matlab
%
%   download_wfdb_records('mitdb', '105', '.');
%   [~,ecg,Fs]=rdsamp('mitdb/105',1);
%   bpfecg = bpfilt(ecg,Fs,4,45,[],0); % prefilter in range [4-45] Hz
%
%   anns_jqrs = wjqrs(bpfecg,Fs,0.3,0.250,10); % jqrs running on each segment of 10 sec length



% TODO: manage sign change.

%= general
segsizeSamp = round(ws*fs); % convert window into nb of samples
NbSeg = floor(length(ecg)/segsizeSamp); % nb of segments
qrs = cell(NbSeg,1);

if NbSeg == 0
    NbSeg=1;
end
    
%= First subsegment
% first subsegment - look forward 1s
dTplus=round(fs);
dTminus=0;
start=1;
stop=segsizeSamp;

%= if no more data, don't look ahead
if NbSeg==1
    dTplus=0;
    stop=length(ecg);
end

qrs_temp=mhrv.ecg.jqrs(ecg(start-dTminus:stop+dTplus),fs,thres,rp,0);
qrs{1} = qrs_temp(:);

start = start+segsizeSamp;
stop = stop+segsizeSamp;

% for each segment perform qrs detection
for ch=2:NbSeg-1

    % take +/-1sec around selected subsegment exept for the borders. This
    % is in case there is a qrs in between segments -> allows to locate
    % them well.
    dTplus  = round(fs);
    dTminus = round(fs);

    qrs_temp=mhrv.ecg.jqrs(ecg(start-dTminus:stop+dTplus),fs,thres,rp,0);

    NewQRS = (start-1)-dTminus+qrs_temp;
    NewQRS(NewQRS>stop) = [];
    NewQRS(NewQRS<start) = [];

    if ~isempty(NewQRS) && ~isempty(qrs{ch-1})
        % this is needed to avoid multiple detection at the transition point
        NewQRS(NewQRS<qrs{ch-1}(end)) = [];
        if ~isempty(NewQRS) && (NewQRS(1)-qrs{ch-1}(end))<rp*fs
            % between two windows
            NewQRS(1) = [];
        end

    end
    qrs{ch} = NewQRS(:);

    start = start+segsizeSamp;
    stop = stop+segsizeSamp;
end

%check there is more than one segment otherwise
if NbSeg>1
    % last subsegment
    ch = NbSeg;
    stop  = length(ecg);
    dTplus  = 0;
    dTminus = round(fs);
    qrs_temp=mhrv.ecg.jqrs(ecg(start-dTminus:stop+dTplus),fs,thres,rp,0);

    NewQRS = (start-1)-dTminus+qrs_temp;
    NewQRS(NewQRS>stop) = [];
    NewQRS(NewQRS<start) = [];

    if ~isempty(NewQRS) && ~isempty(qrs{ch-1})
        % this is needed to avoid multiple detection at the transition point
        NewQRS(NewQRS<qrs{ch-1}(end)) = [];
        if ~isempty(NewQRS) && (NewQRS(1)-qrs{ch-1}(end))<rp*fs
            % between two windows
            NewQRS(1) = [];
        end

    end
    qrs{ch} = NewQRS(:);
end

%= convert to double
qrs = vertcat(qrs{:});
qrs = qrs';

end
