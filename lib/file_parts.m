function [ PATHSTR,NAME,EXT ] = file_parts( FILE )
%FILE_PARTS Similar to builtin fileparts but handles files in the pwd correctly
%   The bulitin fileparts function returns an empty string as PATHSTR if FILE
%   is in the current matlab working directory.
%   This function is a simple wrapper around the built in fileparts that returns
%   the string '.' (current directory) in this case.

% Invoke original function    
[PATHSTR,NAME,EXT] = fileparts(FILE);

% Handle empty PATHSTR
if isempty(PATHSTR)
    PATHSTR = '.';
end
end
