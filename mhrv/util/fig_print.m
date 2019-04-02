function [] = fig_print( fig_handle, out_filename, varargin )
%FIG_PRINT Prints a figure to file.
%   This function sets various figure properties and then prints it to a specified format.
%   Default format is EPS which can then be imported into
%   a LaTeX document and will maintain it's properties.
%   Note that A4 size is 21.0 x 29.7 cm.

%% Input

% Defaults
DEFAULT_WIDTH = 15; % cm
DEFAULT_HEIGHT = 10; % cm
DEFAULT_FONT_SIZE = 12; % pt
DEFAULT_FONT_WEIGHT = 'bold'; % 'bold', 'italic'
DEFAULT_FONT = 'Times';
DEFAULT_OUTPUT_FORMAT = 'pdf'; % pdf, epsc, tiff, ...
DEFAULT_RENDERER = 'painters';
DEFAULT_AXES_LINE_WIDTH = 1.0; % pt
DEFAULT_TITLE = [];
DEFAULT_NOTITLES = false;
DEFAULT_SAVE_FIGURE = false;

% Define input
p = inputParser;
p.addRequired('fig_handle', @ishandle);
p.addRequired('out_filename', @ischar);
p.addParameter('width', DEFAULT_WIDTH, @isscalar);
p.addParameter('height', DEFAULT_HEIGHT, @isscalar);
p.addParameter('font_size', DEFAULT_FONT_SIZE, @isscalar);
p.addParameter('font_weight', DEFAULT_FONT_WEIGHT, @isscalar);
p.addParameter('font', DEFAULT_FONT, @ischar);
p.addParameter('output_format', DEFAULT_OUTPUT_FORMAT, @(x)ischar(x)||isempty(x));
p.addParameter('renderer', DEFAULT_RENDERER, @(x)strcmp(x,'painters')||strcmp(x,'opengl'));
p.addParameter('axes_line_width', DEFAULT_AXES_LINE_WIDTH, @isscalar);
p.addParameter('title', DEFAULT_TITLE, @ischar);
p.addParameter('notitles', DEFAULT_NOTITLES, @islogical);
p.addParameter('save_figure', DEFAULT_SAVE_FIGURE, @islogical);

% Get input
p.parse(fig_handle, out_filename, varargin{:});
width = p.Results.width;
height = p.Results.height;
font_size = p.Results.font_size;
font_weight = p.Results.font_weight;
font = p.Results.font;
output_format = p.Results.output_format;
renderer = p.Results.renderer;
axes_line_width = p.Results.axes_line_width;
axes_title = p.Results.title;
notitles = p.Results.notitles;
save_figure = p.Results.save_figure;

% Allow empty output format to specify the default should be used
if isempty(output_format)
    output_format = DEFAULT_OUTPUT_FORMAT;
end

%% Clone the figure and make it invisible

orig_gcf = gcf;
try
    fig_handle = copyobj(fig_handle, 0);
    set(fig_handle, 'Visible', 'off');
    delete_fig = true;
catch e
    warning('Failed to copy figure for printing to file: %s\nOriginal figure will be modified.', e.message);
    delete_fig = false;

    % Clean up if a new figure was created (partial copy)
    if gcf ~= orig_gcf
        delete(gcf)
    end
end

%% Update the figure and axes

% Get the figure's current on-screen position in cm
set(fig_handle, 'PaperUnits', 'centimeters', 'Units', 'centimeters');
position_cm = get(fig_handle, 'Position');
x0 = position_cm(1); y0 = position_cm(2);

% Set absolute dimentions for figure and paper
set(fig_handle, ...
    'Position', [ x0, y0, width, height ], ...
	'PaperPositionMode', 'auto', ...
    'PaperPosition', [ 0, 0, width, height ], ...
    'PaperSize', [ width, height ], ...
	'InvertHardCopy', 'on');

% Find all axis objects and set their properties
all_axes = findall(fig_handle, 'type', 'axes');
set(all_axes, ...
    'box','off', ...
    'FontUnits', 'points', ...
    'FontWeight', font_weight, ...
    'FontSize', font_size, ...
    'FontName', font, ...
    'LineWidth', axes_line_width);

% Set title if specified. Will be set only to first axes.
if (~isempty(axes_title) && ~notitles)
    title(all_axes(end), axes_title, 'FontName', font, 'FontWeight', font_weight, 'FontSize', font_size);
end

% Set font for all text objects
all_text = findall(fig_handle, 'type', 'text');
set(all_text, 'FontName', font, 'FontSize', font_size, 'FontWeight', font_weight);

% Set font for legend
lgd = findall(fig_handle, 'type', 'legend');
set(lgd, 'FontName', font, 'FontSize', font_size, 'FontWeight', font_weight);

% Make sure output folder exists
out_filename = regexprep(out_filename, ' ', '_'); % replace spaces in filename
[out_dir, ~, ~] = file_parts(out_filename);
[~, ~, ~] = mkdir(out_dir);

% Print figure to file
print(fig_handle, out_filename, ['-d' output_format], ['-' renderer]);

% Save .fig if requested
if save_figure
    savefig(fig_handle, out_filename);
end

%% Clean up
if delete_fig
    delete(fig_handle);
end
end

