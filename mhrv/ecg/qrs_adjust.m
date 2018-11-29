function cqrs = qrs_adjust(ecg,qrs,fs,inputsign,tol,debug)
%This function [1]_ is used to adjust the qrs location by looking for a local
%min or max around the input qrs points.  For example, this is useful when
%parts of the qrs are located on a positive part of the R-wave and parts on a
%negative part of the R-wave in order to make them all positive or negative -
%this can be useful for heart rate variability analysis. It is also useful for
%template substraction in the context of non-invasive fetal ECG source
%separation in order to ensure the maternal template is well aligned with each
%beat.
%
%:param ecg: vector of ecg signal amplitude (mV)
%:param qrs: peak position (sample number)
%:param fs: sampling frequency (Hz)
%:param inputsign: sign of the peak to look for (-1 for negative and 1 for
%   positive)
%:param tol: tolerance window (sec)
%:param debug: (boolean)
%
%:returns:
%
%   - cqrs: adjusted (corrected) qrs positions (sample number)
%
%Example:
%
%.. code-block:: matlab
%
%   download_wfdb_records('mitdb', '105', '.');
%   [~,ecg,Fs]=rdsamp('mitdb/105',1);
%   bpfecg = bpfilt(ecg,Fs,4,45,[],0); % prefilter in range [4-45] Hz
%   anns_jqrs = wjqrs(bpfecg,Fs,0.3,0.250,10); % jqrs running on each segment of 10 sec length
%
%   cqrs = qrs_adjust(ecg,anns_jqrs,Fs,-1,0.050,1);


% == general
cqrs = zeros(length(qrs),1); % corrected qrs vector
NB_qrs = length(qrs);
WINDOW  = ceil(fs*tol); % allow a maximum of tol in sec shift
NB_SAMPLES = length(ecg);

SIGN = inputsign;

% == local refinement to correct for sampling freq resolution
for i=1:NB_qrs
    if qrs(i)>WINDOW && qrs(i)+WINDOW<NB_SAMPLES
        if SIGN>0
            [~,indm] = max(ecg(qrs(i)-WINDOW:qrs(i)+WINDOW));
            cqrs(i) = qrs(i)+indm-WINDOW-1;
        else
            [~,indm] = min(ecg(qrs(i)-WINDOW:qrs(i)+WINDOW));
            cqrs(i) = qrs(i)+indm-WINDOW-1;
        end
    elseif qrs(i)<WINDOW
        % managing left boder
         if SIGN>0
            [~,indm] = max(ecg(1:qrs(i)+WINDOW));
            cqrs(i) = indm;
        else
            [~,indm] = min(ecg(1:qrs(i)+WINDOW));
            cqrs(i) = indm;
        end           
    elseif qrs(i)+WINDOW>NB_SAMPLES
        % managing right border
         if SIGN>0
            [~,indm] = max(ecg(qrs(i)-WINDOW:end));
            cqrs(i) = qrs(i)+indm-WINDOW-1;
        else
            [~,indm] = min(ecg(qrs(i)-WINDOW:end));
            cqrs(i) = qrs(i)+indm-WINDOW-1;
        end           
    else
        cqrs(i) = qrs(i);
    end
end
    


% == plots
if debug || isempty(nargout)
    plot(ecg); hold on, plot(qrs, ecg(qrs),'ok');
    hold on, plot(cqrs, ecg(cqrs),'or');
    legend('ecg','qrs initial','qrs adjusted');
    set(findall(gcf,'type','text'),'fontSize',14,'fontWeight','bold');
end


end





