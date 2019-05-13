function [ sd1, sd2, plot_data ] = poincare( rri, varargin )
%Calculates HRV metrics from a Poincaré plot of the input data.
%
%:param rri: Row vector of RR-interval lengths in seconds.
%:param varargin: Pass in name-value pairs to configure advanced options:
%
%   - sd1_factor: Factor to multiply the standard devation along the
%     perpendicular line (SD1) to get the radius of the ellipse along that axis.
%     Default is 2 (so over 95% of points will be inside the ellipse).
%   - sd2_factor: As above, but for the standard deviation along the line of
%     identity (SD2).  Default: 3.
%   - plot: true/false whether to generate a plot. Defaults to true if no
%     output arguments were specified.
%
%:returns:
%
%   - sd1: Standard deviation of RR intervals along the axis perpendicular to
%     the line of identity.
%   - sd2: Standard deviation of RR intervals along the line of identity.

import mhrv.defaults.*;

%% === Input

% Defaults
% Note that 2 * std means over 95% of points should be inside the ellipse (if an ellipse fits the
% data well).
DEFAULT_SD1_FACTOR = 2;
DEFAULT_SD2_FACTOR = 2;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('sd1_factor', DEFAULT_SD1_FACTOR, @(x) isnumeric(x) && isscalar(x));
p.addParameter('sd2_factor', DEFAULT_SD2_FACTOR, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rri, varargin{:});
sd1_factor = p.Results.sd1_factor;
sd2_factor = p.Results.sd2_factor;
should_plot = p.Results.plot;

% Normalize input shape to row vector
rri = reshape(rri, 1, length(rri));

% Create x and y vectors (_old is data in the original coordinate system)
x_old = rri(1:end-1);   % RR(n)
y_old = rri(2:end);     % RR(n+1)

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
plot_data.x_orig = x_old;
plot_data.y_orig = y_old;
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

