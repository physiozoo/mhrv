function bpfecg = bpfilt(ecg,fs,lcf,hcf,nt,debug)
%This function [1]_ is made for prefiltering an ecg time series before it is
%passed through a peak detector. Of important note: the upper cut off (hcf) and
%lower cutoff (lcf) of the bandpass filter that are applied, highly depends on
%the mammal that is being considered. This is particularly true for the hcf
%which will be higher for a mouse ECG file versus a Human ecg. This is because
%the QRS is `sharper' for a mouse ecg than for a Human one. Of note, NaN should
%be represented by the value -32768 in the ecg (WFDB standard).
%
%:param ecg: electrocardiogram (mV)
%:param fs: sampling frequency (Hz)
%:param lcf: low cut-off frequency (Hz)
%:param hcf: high cut-off frequency (Hz)
%:param debug: plot output filtered signal (boolean)
%:param nt: frequency to cut with a Notch filter (Hz). Leave the field empty
%   ('[]') if you do not want the Notch filter to be applied.
%
%:returns:
%
%   - bpfecg: band pass filtered ecg signal
%
%Example: preprocess an ecg recording from the mitdb (physionet.com) by applying a bandpass filter (0.5-100 Hz)
%
%.. code-block:: matlab
%
%   download_wfdb_records('mitdb', '105', '.');
%   [~,ecg,Fs]=rdsamp('mitdb/105',1);
%
%   bpfecg = bpfilt(ecg,Fs,0.5,100,[],1);

% == check NaN
ecg(isnan(ecg))=-32768;

% == prefiltering
LOW_CUT_FREQ = lcf;
HIGH_CUT_FREQ = hcf;
[b_bas,a_bas] = butter(2,LOW_CUT_FREQ/(fs/2),'high');
[b_lp,a_lp] = butter(5,HIGH_CUT_FREQ/(fs/2),'high');
bpfecg = ecg'-filtfilt(b_lp,a_lp,double(ecg'));
bpfecg = filtfilt(b_bas,a_bas,double(bpfecg'));

if ~isempty(nt)
    wo = nt/(fs/2);  bw = wo/35;
    [b,a] = iirnotch(wo,bw);
    bpfecg = filtfilt(b,a,bpfecg);
end

if debug
    plot(ecg);
    hold on, plot(bpfecg,'r');
    legend('raw','filtered')
end

end
