function [ tool_path ] = get_wfdb_tool_path( tool_name, base_search_path )
%Returns the path to a wfdb tool, takes OS into account Looks for the given
%tool recursively under the current MATLAB directory (or a given directory),
%and then recursively under the folders in the ``$PATH`` environment variable. In
%case the tool is found, the containing directory path will be persisted to
%speed up the next search.
%
%:param tool_name: A string containg the name of the wfdb tool, e.g. 'gqrs',
%   'wfdb-config', 'rdsamp' etc. Should not include a file extension.
%:param base_search_path: Optional. An absolute path to use as a base for
%   searching for the tool.  If not provided defaults to pwd().
%
%:returns:
%
%   - tool_path - The path of the wfdb tool, including it's os-specific
%     file extension (e.g. .exe). In case the tool wasn't found, an error
%     will be raised.
%

% Make sure tool name format is valid
if (~ischar(tool_name) || isempty(tool_name))
    error(['invalid wfdb tool name ''', tool_name, '''']);
end

% Default base search path if it wasn't provided
if (nargin == 1)
    base_search_path = pwd;
end

% On windows, append .exe to the tool name
if (ispc)
    tool_name = [tool_name '.exe'];
end

% Check for a persisted wfdb_path variable, if it exists only search that
persistent wfdb_path;
if ~isempty(wfdb_path)
    tool_path = [wfdb_path, filesep(), tool_name];
    if exist(tool_path, 'file')
        tool_path = escape_spaces(tool_path);
        return;
    else
        % Issue warning but don't exit so that we also look under pwd and $PATH
        warning(['Could not find the wfdb tool ''', tool_name, ...
                 '''. Searched in: ', wfdb_path,'. Will now search under pwd and $PATH']);
    end
end

% Search under base_search_path and $PATH for the tool.
search_path = [strsplit(genpath(base_search_path), pathsep()), strsplit(getenv('PATH'), pathsep())];

% Remove anything under .git/ and remove empty entries
filter_ind = cellfun(@(x) ~isempty(x) && isempty(regexp(x, '[.]git', 'once')), search_path);
search_path = search_path(filter_ind);

% Search for the tool
for path_idx = 1:length(search_path)
    tool_path = [search_path{path_idx}, filesep(), tool_name];
    % Check if the path exists but is not an .m file (sadly exist() returns
    % true if input has no extension and a matching .m file exists).
    if exist(tool_path, 'file') && ~exist([tool_path '.m'], 'file')
        % Update wfdb_path for next time
        wfdb_path = search_path{path_idx};
        tool_path = escape_spaces(tool_path);
        return;
    end
end

% Print an error with the path in case we didn't find anything
error(['Could not find the wfdb tool ''', tool_name, ...
       '''. Searched in: ', strjoin(search_path, pathsep())]);


   %% Helper function
    function escaped_path = escape_spaces(path)
        if ispc
            escape_seq = '^ ';
        else
            escape_seq = '\\ ';
        end
        escaped_path = regexprep(path, '\s+', escape_seq);
    end

end
