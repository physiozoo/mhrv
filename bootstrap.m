%% BOOTSTRAP
% Please run this script before using the toolkit.
% It will initialize the matlab path and environment for the rhrv tools.
% To set custom user-specific options, edit the file cfg/rhrv_config.m before running this.

%% Reset workspaces
close all;
clear variables;

%% Set up matlab path

% Find source and dependencies directories
basepath_ = fileparts(mfilename('fullpath'));
lib_dir_ = [basepath_ '/lib/'];
src_dir_ = [basepath_ '/src/'];
cfg_dir_ = [basepath_ '/cfg/'];
bin_dir_ = [basepath_ '/bin/'];

% Change directory to the root of project
cd(basepath_);

% Add them to matlab's path including subfolders
addpath(genpath(lib_dir_));
addpath(genpath(src_dir_));

%% Load user configuration
run([cfg_dir_ '/rhrv_config.m']);

% Make sure WFDB tools are installed. If not, download them now.
try
    wfdb_config_bin_ = get_wfdb_tool_path('wfdb-config');
catch e
    warning('WFDB binaries not detected, attempting to download...');
    download_wfdb(bin_dir_);
    wfdb_config_bin_ = get_wfdb_tool_path('wfdb-config');
end

% Check WFDB tools version
supported_version_ = '10.5.24';
[~, wfdb_version_] = jsystem([wfdb_config_bin_ ' --version'], 'noshell');
ver_cmp_ = vercmp(wfdb_version_, supported_version_);
if ver_cmp_ < 0
    warning('Detected WFDB version (%s) is older than the tested version, please use %s or newer', wfdb_version_, supported_version_);
elseif ver_cmp_ > 0
    disp('Notice: Detected WFDB version (%s) is newer than the tested version (%s)', wfdb_version_, supported_version_);
end

% Default sizes for figres
set(0,'DefaultAxesFontSize', rhrv_cfg_.plots.font_size);
set(0,'DefaultLineLineWidth', rhrv_cfg_.plots.line_width);
set(0,'DefaultLineMarkerSize', rhrv_cfg_.plots.marker_size);

%% Clean up
clear -regexp _$
