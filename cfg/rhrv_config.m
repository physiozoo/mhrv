function rhrv_cfg = rhrv_config()
%%%  Configuration file for the rhrv toolkit.
%%%
%%% Use this file to set user-specific settings.

rhrv_cfg = struct;

%% Configure paths
% All paths here can be relaive (to the root of the repo), or absolute.
rhrv_cfg.paths = struct;

% Specify a path on this system that contains the physionet wfdb executables.
% If left blank, the current matlab directory will be searched recursively, followed
% by the directories in the $PATH environment variable.

rhrv_cfg.paths.wfdb_path = '';

%% Configure plots
rhrv_cfg.plots = struct;

% Specify desired object sizes for figures.
rhrv_cfg.plots.font_size = 12;
rhrv_cfg.plots.line_width = 1.0;
rhrv_cfg.plots.marker_size = 4;

%% Default parameters file

% Set this to a file in the cfg/ directory containing desired default values of various toolbox
% parameters. This is usefult if you want the toolbox to be initialized with specific parameters
% after calling rhrv_init.
rhrv_cfg.params_file = ''; % e.g. 'human', 'canine'.
