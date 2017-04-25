function [ sd1, sd2, outlier_idx, plot_data ] = poincare( rri, varargin )
%POINCARE Poincare-plot HRV metrics and outlier detection
%   Calculates HRV statistics from a poincare plot of the input data. In adition, this function fits
%   an ellipse to the data and finds suspected outliers, i.e. intervals that lie outside the
%   ellipse.
%
%   Input:
%       - rri: Row vector of RR-interval lengths in seconds.
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - sd1_factor: Factor to multiply the standard devation along the perpendicular line (SD1)
%             to get the radius of the ellipse along that axis. Default is 2 (so over 95% of points
%             will be inside the ellipse).
%           - sd2_factor: As above, but for the standard deviation along the line of identity (SD2).
%             Default: 3.
%           - rr_min: Min physiological RR interval, in seconds. Intervals shorter than this will
%             be removed prior to poincare plotting. Default: 0.32 sec.
%           - rr_max: Max physiological RR interval, in seconds. Intervals longer than this will
%             be removed prior to poincare plotting. Default: 1.5 sec.
%           - rr_max_change: Maximal change, in percent, allowed between adjacent RR intervals.
%             Intervals violating this will be removed prior to poincare plotting. Default: 25.
%           - plot: true/false whether to generate a plot. Defaults to true if no output
%                   arguments were specified.
%   Output
%       - sd1: Standard deviation of RR intervals along the axis perpendicular to the line of
%              identity.
%       - sd2: Standard deviation of RR intervals along the line of identity.
%       - outlier_idx: Vector of suspected outlier indices.

%% === Input

% Defaults
% Note that 2 * std means over 95% of points should be inside the ellipse (if an ellipse fits the
% data well).
DEFAULT_SD1_FACTOR = rhrv_default('poincare.sd1_factor', 2);
DEFAULT_SD2_FACTOR = rhrv_default('poincare.sd2_factor', 2);
DEFAULT_RR_MIN = rhrv_default('poincare.rr_min', 0.32); % Seconds (187.5 BPM)
DEFAULT_RR_MAX = rhrv_default('poincare.rr_max', 1.5);  % Seconds (40 BPM)
DEFAULT_RR_MAX_CHANGE = rhrv_default('poincare.rr_max_change', 25); % Percent, max change between adjacent RR intervals

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('sd1_factor', DEFAULT_SD1_FACTOR, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sd2_factor', DEFAULT_SD2_FACTOR, @(x) isnumeric(x) && isscalar(x));
p.addParameter('rr_min', DEFAULT_RR_MIN, @(x) isnumeric(x) && isscalar(x));
p.addParameter('rr_max', DEFAULT_RR_MAX, @(x) isnumeric(x) && isscalar(x));
p.addParameter('rr_max_change', DEFAULT_RR_MAX_CHANGE, @(x) isnumeric(x) && isscalar(x) && x>0 && x<=100);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rri, varargin{:});
sd1_factor = p.Results.sd1_factor;
sd2_factor = p.Results.sd2_factor;
rr_min = p.Results.rr_min;
rr_max = p.Results.rr_max;
rr_max_change = p.Results.rr_max_change;
should_plot = p.Results.plot;

% Normalize input shape to row vector
rri = reshape(rri, 1, length(rri));

%% Square filter: Remove non-physiological intervals

% _orig is the original, unfiltered data
x_orig = rri(1:end-1);   % RR(n)
y_orig = rri(2:end);     % RR(n+1)

% Find intervals that are too large or too small, i.e. non-physiological
square_filter_idx = find(rri < rr_min | rri > rr_max);

%% Quotient filter

rr_max_change = rr_max_change / 100;
rr_q_min = 1.0 - rr_max_change;
rr_q_max = 1.0 + rr_max_change;

% Find intervals that differ by more than a specified percentage from the prev/next interval
quotient_filter_idx = find(x_orig./y_orig < rr_q_min | x_orig./y_orig > rr_q_max | ...
                           y_orig./x_orig < rr_q_min | y_orig./x_orig > rr_q_max);

%% Remove filtered

% For poincare plot, we must remove the intervals both from the x and the y vectors, so for every
% index we found, also use the previous index.
% The square filter finds one problematic interval at a time, so we need to remove it's index and
% the previous index (so it's removed from both x and y vectors).
square_filter_idx_pp = [square_filter_idx, square_filter_idx-1];

% The quotient filter finds a problem in the ratio of two intervals, and we can't know which one of
% them is problematic. So, we'll remove both, meaning we need to remove three interval indices.
quotient_filter_idx = [quotient_filter_idx, quotient_filter_idx+1];
quotient_filter_idx_pp = [quotient_filter_idx, quotient_filter_idx-1];

% Outlier indices for the poincare plot
filter_idx_pp = unique([square_filter_idx_pp, quotient_filter_idx_pp]);
filter_idx_pp(filter_idx_pp < 1 | filter_idx_pp > length(x_orig)) = []; % Make sure no index is out of bounds

% Outlier interval indices in the original RR vector
outlier_idx = unique([square_filter_idx, quotient_filter_idx]);
outlier_idx(outlier_idx < 1 | outlier_idx > length(rri)) = [];

% Remove the filtered intervals from both x and y vectors
% _old is data after filter, but in the old coordinate system
x_old = x_orig; y_old = y_orig;
x_old(filter_idx_pp) = [];
y_old(filter_idx_pp) = [];

%% Rotate input
alpha = -pi/4;

% Rotate the data to the new coordinate system
% _new is the square-filtered data in the new coordinate system
rri_rotated = rotation_matrix(alpha) * [x_old; y_old];
x_new = rri_rotated(1,:);
y_new = rri_rotated(2,:);

% Calculate standard deviation along the new axes
sd1 = sqrt(var(y_new));
sd2 = sqrt(var(x_new));

%% Fit ellipse
% For fitting the ellipse we're using the _new vectors because we don't wan't any non-physiological
% intervals to influence the ellise and SD1/2 metrics.

% Ellipse radii
r_x = sd2_factor * sd2;
r_y = sd1_factor * sd1;

% Ellipse center
c_x = mean(x_new);
c_y = mean(y_new);

% Ellipse parametric equation
t = linspace(0, 2*pi, 200);
xt = r_x * cos(t) + c_x;
yt = r_y * sin(t) + c_y;

% Rotate the ellipse back to the old coordinate system
ellipse_old = rotation_matrix(-alpha) * [xt; yt];

%% Lines for ellipse axes
ellipse_center_new = [c_x; c_y];

% Create the lines in the new coordinate system
sd1_line_new = [0, 0; -sd1, sd1] + [ellipse_center_new, ellipse_center_new];
sd2_line_new = [-sd2, sd2; 0, 0] + [ellipse_center_new, ellipse_center_new];

% Rotate back to the old system
sd1_line_old = rotation_matrix(-alpha) * sd1_line_new;
sd2_line_old = rotation_matrix(-alpha) * sd2_line_new;

%% Plotting
plot_data.name = 'RR Interval Poincare Plot';
plot_data.x_orig = x_orig;
plot_data.y_orig = y_orig;
plot_data.filter_idx_pp = filter_idx_pp;
plot_data.ellipse_old = ellipse_old;
plot_data.sd1_line_old = sd1_line_old;
plot_data.sd2_line_old = sd2_line_old;
plot_data.sd1 = sd1;
plot_data.sd2 = sd2;

if (should_plot)
    figure('Name', plot_data.name);
    plot_poincare_ellipse(gca, plot_data);
end

%% Helper functions

% Creates a 2D rotation matrix
function rotation_mat = rotation_matrix(theta)
    rotation_mat = [cos(theta), -sin(theta); sin(theta), cos(theta)];
end

end

