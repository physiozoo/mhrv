function [ cmp ] = vercmp( ver1, ver2 )
%VERCMP Compares two version strings
%   Compares two strings of version numbers, e.g. '1.2.3' and '1.23.4'.
%   Returns an integer similar to strcmp:
%       -1 if ver1  < ver2
%        0 if ver1 == ver2
%        1 if ver1  > ver2

if ~ischar(ver1) || ~ischar(ver2)
    error('Both inputs must be strings');
end

% Split version strings into ordinal numbers
vals1 = strsplit(ver1, '.');
vals2 = strsplit(ver2, '.');

% Move index to first non-equal ordinal (or length of shortest string)
i = 1;
while (i <= length(vals1) && i <= length(vals2) && strcmp(vals1{i}, vals2{i}))
    i = i + 1;
end

if (i <= length(vals1) && i <= length(vals2))
    % Compare first non-equal ordinal
    diff = str2double(vals1{i}) - str2double(vals2{i});
else
    % The strings are equal or one is a substring, use length to compare
    diff = length(vals1) - length(vals2);
end

cmp = sign(diff);