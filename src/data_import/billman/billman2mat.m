function [ data_bsl, data_dbk, metadata ] = billman2mat( input_file_path )
%BILLMAN2MAT Read data from Billman's 2013/2015 studies [1,2] data into matlab variables. 
%   Reads data in ACQ format from the study and extracts the basal and
%   double blockade data segments.
%
%   inputs:
%       - input_file_path: path to input file (.acq).
%   outputs:
%       - data_bsl: Nx2 matrix containing the basal (pre-blockade)
%                   signals, where column 1 is ECG, and column 2 is HR.
%       - data_dbk: Nx2 matrix containing the double blockade (pre-blockade)
%                   signals, where column 1 is ECG, and column 2 is HR.
%       - metadata: struct containing the following fields:
%           * fs: signal sampling frequency for all channels.
%           * channels: 1x2 cell array containing channel names (ECG,
%                       HR) in the order of the data matrix.
%           * units: 1x2 cell array containing the units of each channel
%                    (e.g. mV or BPM).
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

%% Validate input

% Split the input filename
[~, input_file_name ,input_file_ext] = fileparts(input_file_path);

% Make sure input file path exists
if (~exist(input_file_path, 'file'))
    error(['Input file ''' input_file_path ''' doesn''t exist']);
end

% Make sure it's an ACQ file
if (strcmp(input_file_ext, 'acq') ~= 0)
    error(['Input file ''' input_file_path ''' should be an ACQ file']);
end

%% Read raw data from input file

% Use our own custom read_acq function that also handles scaling and offsetting
% the data, and creates a time axis.
[t, data, fs, info] = read_acq(input_file_path);

% Convert data to matrix (this also make sure both channels in data have
% the same number of samples so they can share a time axis)
data = cell2mat(data);

% Take the first time axis as the time axis for both channels
t = t{1};

% The szText field contains the segment labels. Make sure it exists
if (isempty(info.szText)); info.szText = {}; end

%% Find the channels with ECG and HR data
ecg_channel = 0; hr_channel = 0;

for jj = 1:info.nChannels
    if (~isempty(regexpi(info.szCommentText{jj}, 'ecg')))
        ecg_channel = jj;
    end
    if (~isempty(regexpi(info.szCommentText{jj}, 'hr|heart rate|heartrate')))
        hr_channel = jj;
    end
end

% Make sure we've found both channels
if (ecg_channel == 0)
    error(['No ECG channel found for file ', input_file_name]);
end
if (hr_channel == 0)
    error(['No HR channel found for file ', input_file_name]);
end

%% Find atropine and propranolol segments

atropine_segment = 0; propranolol_segment  = 0;
% Go over segment labels to find if and when atropine and propranolol were administered
for jj = 1:length(info.szText)
    label_text = info.szText{jj};
    
    % look for matches in the label text (take into account the spelling mistakes that exist in the files...
    if (atropine_segment == 0 && ~isempty(regexpi(label_text, 'atropine|atopine')))
        atropine_segment = jj;
    end
    
    if (propranolol_segment == 0 && ~isempty(regexpi(label_text, 'propranolol|prorpanolol|proprnaolol|prortpanolol|bb')))
        propranolol_segment = jj;
    end
    
    % Skip next segments for this file if both segments were found
    if (atropine_segment > 0 && propranolol_segment > 0)
        break;
    end
end

% Make sure we found both segments
if (atropine_segment == 0 || propranolol_segment == 0)
    error('Failed to find both atropine and propranolol segments');
end

% Make sure the segments we found are adjacent
if (abs(propranolol_segment - atropine_segment) ~= 1)
    error('Non-adjacent atropine and propranolol segments found');
end

%% Create index ranges for the basal and double blockade data

% Get basal data indices: This is all the data until either the atropine or
% propranolol marker (whatever comes first).
% Add 1 because the indices in the file start from zero
idx_basal_low = 1;
idx_basal_high = 1 + double(info.lSample(min([atropine_segment, propranolol_segment])));

% Get double-blockade data indices: This is the data from the segment with both atropine and propranolol
% until the next segment (if exists) or until end of data.
% Add 1 because the indices in the file start from zero.
dbk_seg = max([atropine_segment, propranolol_segment]);
idx_blockade_low = 1 + double(info.lSample(dbk_seg));

% If the blockade segment is the last segment, take data till end
if (dbk_seg == length(info.szText))
    idx_blockade_high = length(t);
else
    idx_blockade_high = 1 + double(info.lSample(dbk_seg+1));
end

% Print the filename and data indices we've found
fprintf('%s: [%d~%d], [%d~%d] - %s\n', input_file_name,...
    idx_basal_low, idx_basal_high, idx_blockade_low, idx_blockade_high,...
    strjoin(info.szText, ', '));

%% Extract the data from the segments

% Create index vectors
idx_basal = idx_basal_low:idx_basal_high;
idx_blockade = idx_blockade_low:idx_blockade_high;

% Create Nx2 data matrices where the first column is ECG and the second is HR
data_bsl = [data(idx_basal, ecg_channel),    data(idx_basal, hr_channel)];
data_dbk = [data(idx_blockade, ecg_channel), data(idx_blockade, hr_channel)];

%% Create metadata

% Save fs in output
metadata = struct;
metadata.fs = fs;

% Save channel names in output
metadata.channels = {'ECG', 'Heart Rate'};

% Add units to metadata
metadata.units = {info.szUnitsText{ecg_channel}, info.szUnitsText{hr_channel}};

end

