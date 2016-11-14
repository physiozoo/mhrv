function [ bsl_rec, dbk_rec ] = billman2wfdb( input_file_path, output_dir, output_rec_prefix )
%BILLMAN2WFDB Convert a record from Billman's 2013/2015 studies [1,2] to wfdb format.
%   Reads data in ACQ format from the study, extracts the basal and
%   double blockade data segments and writes them to wfdb format files (each segment
%   into a separate wfdb record).
%
%   inputs:
%       - input_file_path: path to input file (.acq).
%       - output_dir: Optional. Folder to write output record to. Will be
%         current dir if not supplied.
%       - output_rec_prefix: Optional. A prefix for the records. Will be
%         the first word in the input filename if not supplied.
%   outputs:
%       - bsl_rec: path to wfdb record containing the basal data.
%       - dbk_rec: path to wfdb record containing the double blockade data.
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
if (nargin < 1)
    error('No input filename supplied');
elseif (nargin < 2)
    output_dir = pwd;
elseif (nargin < 3)
    [~, input_file_name ,~] = fileparts(input_file_path);
    output_rec_prefix = strsplit(input_file_name);
    output_rec_prefix = output_rec_prefix{1};
end

% Make sure output dir exists
if (~exist(output_dir, 'dir'))
    mkdir(output_dir);
end

% Append a file separator to output dir if necessary
if (output_dir(end) ~= filesep)
    output_dir = [output_dir filesep];
end

% Extract basal and blockade segments
[data_basal, data_blockade, metadata] = billman2mat(input_file_path);

% Handle units
units = metadata.units;
for kk = 1:size(units, 2)
    units_text = units{kk};

    % Convert volts to mV (default physionet units)
    if (~isempty(regexpi(units_text, '^volt|^V$')))
        data_basal(:, kk) = data_basal(:, kk) * 1000;
        data_blockade(:, kk) = data_blockade(:, kk) * 1000;
        units_text = 'mV';
    end
    % Remove whitespace from units
    units{kk} = strrep(units_text, ' ', '');
end

% Build output record paths
output_rec = [output_dir, output_rec_prefix];
bsl_rec = [output_rec, '-bsl'];
dbk_rec = [output_rec, '-dbk'];

% Use original filename as a comment in the output record header
[~, input_file_name ,~] = fileparts(input_file_path);
file_comment = ['Original filename: ' input_file_name];

% Write to wfdb file format
mat2wfdb(data_basal,    bsl_rec, metadata.fs, [], units, file_comment, [], metadata.channels);
mat2wfdb(data_blockade, dbk_rec, metadata.fs, [], units, file_comment, [], metadata.channels);
end
