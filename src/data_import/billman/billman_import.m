function [] = billman_import( input_dir, output_dir )
%BILLMAN_IMPORT Convert records from Billman's 2013/2015 studies [1,2] to wfdb format.
%   inputs:  
%       - input_dir: Folder continaing input files in *.acq format.
%       - output_dir: Optional. Folder to write output record to. Will be
%         current dir if not supplied.
%
%   [1] Billman, G. E. (2013). The effect of heart rate on the heart rate variability response to autonomic interventions.
%       Frontiers in Physiology, 4 AUG(August), 1?9.
%       http://doi.org/10.3389/fphys.2013.00222
%
%   [2] Billman, G. E., Cagnoli, K. L., Csepe, T., Li, N., Wright, P., Mohler, P. J., & Fedorov, V. V. (2015).
%       Exercise training-induced bradycardia: evidence for enhanced parasympathetic regulation without changes in
%       intrinsic sinoatrial node function.
%       Journal of Applied Physiology (Bethesda, Md. : 1985), 118(11), 1344?55.
%       http://doi.org/10.1152/japplphysiol.01111.2014


% Make sure input path exists
if (~exist(input_dir, 'dir'))
    error(['Path ''' input_dir ''' doesn''t exist']);
end

% Make sure ouput path exists
if (~exist(output_dir, 'dir'))
    mkdir(output_dir);
end

% Append a file separator to paths if necessary
if (input_dir(end) ~= filesep)
    input_dir = [input_dir filesep];
end
if (output_dir(end) ~= filesep)
    output_dir = [output_dir filesep];
end

% Load input files
files = dir([input_dir '*.acq']);

% Convert each file to a wfdb record, handle any error that may occur
for ii = 1:length(files)
    try
        billman2wfdb([input_dir files(ii).name], output_dir);
    catch ex
        warning(ex.message);
    end
end

end

