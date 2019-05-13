function [dl_recs, dl_ann, dl_files] = download_wfdb_records(...
    db_name, rec_names, outdir, varargin...
    )
%Downloads records from the `PhysioBank <https://physionet.org/physiobank/database/>`_
%database on PhysioNet.
%
%:param db_name: Name of database on physiobank, e.g. ``mitdb``.
%:param rec_names: A string or cell of strings containing a regex pattern to
%   match against the record names from the specified database. Matching
%   will be performed against the entire record name (as if regex is
%   delimited by ^$). Empty array or string will match all records. 
%   See examples below.
%:param outdir: The root directory to download to. A folder with the
%   specified ``db_name`` will be created within it.
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - base_url: Specify an alternative physiobank URL to download from.
%
%:returns:
%
%   - dl_recs: Names of downloaded records.
%   - dl_ann: Names of annotators for downloaded records.
%   - dl_files: Paths to all downloaded files.
%
%
%Examples:
%
%#. Download single record, ``mitdb/100`` to folder ``db/mitdb``:
%
%   .. code-block:: matlab
%
%       download_wfdb_records('mitdb', '100', 'db');
%
%#. Download three specific records from ``mitdb``:
%
%   .. code-block:: matlab
%
%       download_wfdb_records('mitdb', {'100','200','222'}, 'db');
%
%
%#. Download all records starting with '1' (e.g. 100, 101, 122...) from ``mitdb``:
%
%   .. code-block:: matlab
%
%       download_wfdb_records('mitdb', '1\d+', 'db');
%
%
%#. Download records '123', '124' and any record ending with 0 from ``mitdb``:
%
%   .. code-block:: matlab
%
%       download_wfdb_records('mitdb', {'12[3,4]', '\d+0'}, 'db');
%
%
%#. Download all records from ``mitdb``:
%
%   .. code-block:: matlab
%
%       download_wfdb_records('mitdb', [], 'db');
%
%

import mhrv.wfdb.*;

%% Input

% Defaults
DEFAULT_BASE_URL = 'https://www.physionet.org/physiobank/database/';

% Define input
p = inputParser;
p.addRequired('db_name', @(x) ischar(x) && ~isempty(x));
p.addRequired('rec_names', @(x) isempty(x)||ischar(x)||iscellstr(x));
p.addRequired('outdir', @(x) ischar(x) && ~isempty(x));
p.addParameter('base_url', DEFAULT_BASE_URL, @(x) ischar(x) && ~isempty(x));

% Get input
p.parse(db_name, rec_names, outdir, varargin{:});
p = p.Results;

if ischar(rec_names) || isempty(rec_names)
    rec_names = {rec_names};
end

if ~strcmp(p.base_url(end), '/')
    p.base_url = [p.base_url '/'];
end

% Edit patterns
% - Treat empty as match-all.
% - Wrap with ^$ to match the whole name.
for ii = 1:length(rec_names)
    rec_name = rec_names{ii};
    if isempty(rec_name)
        rec_name = '.*';
    end
    if rec_name(1) ~= '^'
        rec_name = ['^' rec_name];
    end
    if rec_name(end) ~= '$'
        rec_name = [rec_name '$'];
    end
    rec_names{ii} = rec_name;
end

%% Make sure DB exsits

db_url = [p.base_url db_name];
if ~check_remote_file_exists(db_url)
    error('The specified database can''t be found: %s', db_url);
end

%% Create output directory

if mkdir(outdir, db_name) == 0
    error('Failed to create output directory %s/%s', outdir, db_name);
end

%% Get DB metadata
t0 = cputime;

try
    db_rec_names = get_records(db_url);
    if ~isempty(db_rec_names)
        fprintf('[%.3f] >> %s: Found %d records\n', cputime-t0, db_name, length(db_rec_names));
    else
        error('No records found');
    end
catch e
    error('Failed to get record names for %s: %s', db_name, e.message);
end

try
    db_ann_exts = get_annotators(db_url);
    if ~isempty(db_ann_exts)
        fprintf('[%.3f] >> %s: Found %d annotators\n', cputime-t0, db_name, length(db_ann_exts));
    else
        error('No annotators found');
    end
catch e
    error('Failed to get annotators names for %s: %s', db_name, e.message);
end

%% Download
dl_recs = {};
dl_ann = {};
dl_files = {};

for ii = 1:length(db_rec_names)
    db_rec_name = db_rec_names{ii};
    
    % Skip unless the db record matches of of the requested record names
    % We're only considering matches starting at the first char.
    if ~any(cellfun(@(r) ~isempty(regexpi(db_rec_name, r)), rec_names))
        continue;
    end
    
    % Annotators & header
    file_exts = [{'hea'}, db_ann_exts];
    for jj = 1:length(file_exts)
        db_ann_ext = file_exts{jj};
        rec_file = [db_rec_name '.' db_ann_ext];
        
        outfile = [outdir filesep db_name filesep rec_file];
        rec_file_url = [db_url '/' rec_file];
        websave(outfile, rec_file_url);
        
        fprintf('[%.3f] >> %s: Downloaded: %s -> %s\n', cputime-t0, db_name, rec_file, outfile);
        dl_files{end+1} = outfile;
    end
    dl_recs{end+1} = db_rec_name;
    dl_ann = db_ann_exts;
    
    % Data
    rec_file = [db_rec_name '.' 'dat'];
    outfile = [outdir filesep db_name filesep rec_file];
    rec_file_url = [db_url '/' rec_file];
    
    % dat file doesn't always exist, so we need a separate check
    if ~check_remote_file_exists(rec_file_url)
        continue;
    end
    websave(outfile, rec_file_url);
    fprintf('[%.3f] >> %s: Downloaded: %s -> %s\n', cputime-t0, db_name, rec_file, outfile);
    dl_files{end+1} = outfile;
end

fprintf('[%.3f] >> %s: Done, %d records downloaded.\n', cputime-t0, db_name, length(dl_recs));
end

%% Helper functions

function [ann_exts] = get_annotators(db_url)
    ann_file_url = [db_url '/' 'ANNOTATORS'];
    data_lines = webread_lines(ann_file_url);
    
    ann_exts = cell(1, length(data_lines));
    for ii = 1:length(data_lines)
        line_split = strsplit(data_lines{ii}, {'\t'});
        ann_exts{ii} = line_split{1};
    end
    if isempty(ann_exts{end})
        ann_exts = ann_exts(1:end-1);
    end
end

function [rec_names] = get_records(db_url)
    records_file_url = [db_url '/' 'RECORDS'];
    rec_names = webread_lines(records_file_url);
    if isempty(rec_names{end})
        rec_names = rec_names(1:end-1);
    end
end

function data_lines = webread_lines(url)
    data = webread(url, weboptions('ContentType', 'text'));
    data_lines = strsplit(data, {'\r?\n'}, 'DelimiterType', 'RegularExpression');
end

function [exists, resp] = check_remote_file_exists(file_url)
    req_headers = [matlab.net.http.HeaderField('Accept-Encoding', 'identity')];
    req = matlab.net.http.RequestMessage('HEAD', req_headers);
    
    try
    resp = req.send(file_url);
    catch e
        error('Communication error occured: %s', e.message);
    end
    exists = (resp.StatusCode == 200);
end

function [size_bytes] = get_remote_file_size(file_url)
    [exists, resp] = check_remote_file_exists(file_url);
    if ~exists
        error('Remote file not found: %s', file_url);
    end

    content_length_field = resp.Header.getFields('content-length');
    size_bytes = uint32(str2double(content_length_field.Value));
end

