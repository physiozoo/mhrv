%% BOOTSTRAP
% Please run this script before using the toolkit.
% It will initialize the matlab path and environment for the rhrv tools.
% To set custom user-specific options, edit the file cfg/rhrv_config.m before running this.

%% Reset workspaces
close all;
clear variables;

% Remove rhrv-realted variables
clearvars -global rhrv_basepath rhrv_default_values;
clear get_wfdb_tool_path;

%% Set up matlab path

% Find source and dependencies directories
basepath_ = fileparts(mfilename('fullpath'));
lib_dir_ = [basepath_ filesep 'lib'];
src_dir_ = [basepath_ filesep 'src'];
cfg_dir_ = [basepath_ filesep 'cfg'];
bin_dir_ = [basepath_ filesep 'bin'];

% Save the root toolbox dir as a global variable
global rhrv_basepath;
rhrv_basepath = basepath_;

% Add them to matlab's path including subfolders
addpath(genpath(lib_dir_));
addpath(genpath(cfg_dir_));
addpath(genpath(src_dir_));

%% Load user configuration & default parameter values
rhrv_config;

global rhrv_default_values;
rhrv_default_values = containers.Map;
if (~isempty(rhrv_cfg_.params_file))
    set_params = str2func(rhrv_cfg_.params_file);
    set_params(rhrv_default_values, cfg_dir_);
end

%% WFDB paths
% Check if user specified a custom wfdb path. If not, use rhrv root folder.
if (isempty(rhrv_cfg_.paths.wfdb_path))
    wfdb_search_path_ = basepath_;
else
    wfdb_search_path_ = rhrv_cfg_.paths.wfdb_path;
end

% Make sure WFDB tools are installed. If not, download them now.
try
    wfdb_config_bin_ = get_wfdb_tool_path('wfdb-config', wfdb_search_path_);
catch e
    warning('WFDB binaries not detected, attempting to download...');
    download_wfdb(bin_dir_);
    wfdb_config_bin_ = get_wfdb_tool_path('wfdb-config', wfdb_search_path_);
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

%% Set default sizes for figres
set(0,'DefaultAxesFontSize', rhrv_cfg_.plots.font_size);
set(0,'DefaultLineLineWidth', rhrv_cfg_.plots.line_width);
set(0,'DefaultLineMarkerSize', rhrv_cfg_.plots.marker_size);

%% Clean up
clear -regexp _$
