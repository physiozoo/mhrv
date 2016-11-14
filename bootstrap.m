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

% Change directory to the root of project
cd(basepath_);

% Add them to matlab's path including subfolders
addpath(genpath(lib_dir_));
addpath(genpath(src_dir_));

%% Load user configuration
run([cfg_dir_ '/rhrv_config.m']);

% Add wfdb location to jsystem path
global jsystem_path;
jsystem_path = {rhrv_cfg_.paths.wfdb_path};

% Default font size for figres
set(0,'DefaultAxesFontSize', rhrv_cfg_.plots.font_size);

%% Clean up
clear -regexp _$
