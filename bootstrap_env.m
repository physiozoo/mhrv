%% BOOTSTRAP_ENV
% Initialize path and environment for the rhrv tools.

%% Reset workspaces
close all;
clear variables;

%% Set up path

% Find source and dependencies directories
basepath_ = fileparts(mfilename('fullpath'));
lib_dir_ = [basepath_ '/lib/'];
src_dir_ = [basepath_ '/src/'];

% Add them to matlab's path including subfolders
addpath(genpath(lib_dir_));
addpath(genpath(src_dir_));

% Save database folder as a global variable
global db_dir
db_dir = [basepath_ '/db/'];

% Add wfdb location to path
global jsystem_path;
jsystem_path = {'/usr/local/bin'};

%% Clean up
clear -regexp _$
