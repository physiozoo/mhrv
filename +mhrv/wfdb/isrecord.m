function [ isrecord ] = isrecord( rec_name, data_ext )
%Checks if the given WFDB record name exists locally.
%
%:param rec_name: Path and name of a wfdb record's files e.g. 'db/mitdb/100'.
%   Can be an absolute or relative path (relative to the MATLAB pwd).
%:param data_ext: Optional. The extension of the data file to look for.
%   Defaults to 'dat' if not specfied.
%
%:returns:
%
%   - isrecord: True if the given record path is valid, otherwise false. Valid
%     means that e.g.  both the files db/mitdb/100.dat (or another extension as
%     specified in 'data_ext') and db/mitdb/100.hea exist if rec_name was
%     'db/mitdb/100').


% Default for the data file extension
if nargin < 2
    data_ext = 'dat';
end

% Make sure record file exists
if (~exist([rec_name '.' data_ext], 'file') || ~exist([rec_name '.hea'], 'file'))
    isrecord = false;
    return;
end

isrecord = true;

end

