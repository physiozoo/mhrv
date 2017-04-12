function [] = rhrv_init( varargin )
%% RHRV_INIT Initialize MATLAB environment of the rhrv tools.
% Run this script before using the toolkit.
% It will initialize the matlab path and environment for the rhrv tools, and also download the
% PhysioNet tools if they are not found on this system.
% To set custom user-specific options (e.g. PhysioNet tools location), edit the file
% cfg/rhrv_config.m before running this.
% By default this script won't do anything if it was run previously during the same MATLAB session.
%
%   Usage:
%       rhrv_init [-f/--force] [-c/--close]
%
%   * The --force/-f option forces running of this script again, even if it was run before.
%   * The --close/-c option causes the script to close all open figures.

%% Parse input
should_force = false;
should_close = false;
for i = 1:length(varargin)
    curr_arg = varargin{i};
    if strcmp(curr_arg, '-f') || strcmp(curr_arg, '--force') 
        should_force = true;
    elseif strcmp(curr_arg, '-c') || strcmp(curr_arg, '--close')
        should_close = true;
    end
end

%% Check if already initialized
global rhrv_initialized;
if (~isempty(rhrv_initialized) && ~should_force)
    return;
end

%% Reset workspaces
% Remove rhrv-realted variables
clearvars -global rhrv_basepath rhrv_initialized rhrv_default_values;
clear get_wfdb_tool_path;

if should_close
    close all;
end

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

%% Load user configuration
rhrv_cfg_ = rhrv_config;

if (~isempty(rhrv_cfg_.params_file))
    rhrv_load_params(rhrv_cfg_.params_file);
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

%% Mark initialization
rhrv_initialized = true;