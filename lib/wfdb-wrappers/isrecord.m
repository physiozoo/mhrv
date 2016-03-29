function [ isrecord ] = isrecord( rec_name )
%ISRECORD Check the given WFDB record name to make sure it's files exist.
%   Detailed explanation goes here

% Make sure record file exists
if (~exist([rec_name '.dat'], 'file') || ~exist([rec_name '.hea'], 'file'))
    isrecord = false;
    return;
end

isrecord = true;

end

