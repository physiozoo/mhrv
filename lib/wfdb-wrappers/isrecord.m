function [ isrecord ] = isrecord( rec_name )
%ISRECORD Checks if the given WFDB record name exists locally.
%   Input:
%       - rec_name: Path and name of a wfdb record's files e.g. 'db/mitdb/100'. Can be an absolute or
%                   relative path (relative to the MATLAB pwd).
%   Output:
%       - isrecord: True if the given record path is valid, otherwise false. Valid means that e.g.
%                   both the files db/mitdb/100.dat and db/mitdb/100.hea exist
%                   (if rec_name was 'db/mitdb/100').

% Make sure record file exists
if (~exist([rec_name '.dat'], 'file') || ~exist([rec_name '.hea'], 'file'))
    isrecord = false;
    return;
end

isrecord = true;

end

