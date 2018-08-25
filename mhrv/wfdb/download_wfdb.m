function bin_path = download_wfdb(dest_base_dir)
%Downloads the WFDB binaries for this OS.  This function detects the current OS
%and attempts to download the approprate WFDB binaries.  By default they will
%be downloaded into the folder 'bin/wfdb' under the current MATLAB directory.
%
%:param dest_base_dir: Optional. Directory to download into. Will be created if
%   it doesn't exist.  A folder name 'wfdb' will be created inside. If this is not
%   provided, defaults to the folder 'bin/' under the current MATLAB directory.
%
%:returns:
%
%   - bin_path: Path the the directory containing the WFDB binaries that were
%     downloaded.

%% Check input
if nargin == 0
    dest_base_dir = 'bin';
end

% Make sure destination exists
if ~exist(dest_base_dir, 'dir')
    mkdir(dest_base_dir)
end
output_dir = [dest_base_dir '/wfdb'];

%% Determine Download URL for the current OS
t0 = cputime;

% OSX
if (ismac)
    fprintf('[%.3f] >> download_wfdb: Detected OSX.\n', cputime-t0);
    url = 'https://homebrew.bintray.com/bottles-science/wfdb-10.5.24.yosemite.bottle.1.tar.gz';
end

% Windows
if (ispc)
    if strcmpi(computer('arch'), 'win32')
        fprintf('[%.3f] >> download_wfdb: Detected Win32.\n', cputime-t0);
        url = 'http://physionet.org/physiotools/binaries/windows/wfdb-10.5.24-mingw32.zip';
    else
        fprintf('[%.3f] >> download_wfdb: Detected Win64.\n', cputime-t0);
        url = 'http://physionet.org/physiotools/binaries/windows/wfdb-10.5.24-mingw64.zip';
    end 
end

% Linux
if (isunix && ~ismac)
    fprintf('[%.3f] >> download_wfdb: Detected Linux.\n', cputime-t0);
    url = 'https://physionet.org/physiotools/binaries/intel-linux/wfdb-10.5.8-i686-Linux.tar.gz';
end

%% Clear output dir if necessary, but ask user first...
if exist(output_dir, 'dir')
    fprintf('[%.3f] >> download_wfdb: Output folder %s exists. Type ''YES'' to remove: ', cputime-t0, output_dir);
    user_response = input('', 's');
    if strcmp(user_response, 'YES')
        rmdir(output_dir, 's');
    else
        error('Must remove existing binary dir to re-download');
    end
end

%% Download archive
fprintf('[%.3f] >> download_wfdb: Downloading %s...\n', cputime-t0, url);

[~, url_filename, url_ext] = fileparts(url);
local_file = [dest_base_dir, filesep(), url_filename, url_ext];
urlwrite(url, local_file);

%% Extract archive
fprintf('[%.3f] >> download_wfdb: Extracting %s...\n', cputime-t0, local_file);

if regexpi(url, '.tar.gz$')
    untar(local_file, output_dir);
elseif regexpi(url, '.zip$')
    unzip(local_file, output_dir);
else
    error('Unexpected file extension');
end

% Remove downloaded archive
delete(local_file);

%% Find the bin/ directory
bin_path = [];
paths = strsplit(genpath(output_dir), pathsep());
for idx = 1:length(paths)
    [~, dirname, ~] = fileparts(paths{idx});
    if strcmp(dirname, 'bin')
        bin_path = paths{idx};
        break;
    end
end

if isempty(bin_path)
    error('Failed to find wfdb binaries directory in extracted archive');
end

fprintf('[%.3f] >> download_wfdb: WFDB binaries extracted to %s.\n', cputime-t0, bin_path);
end
