function [ sd1, sd2, outlier_idx ] = poincare( rri, varargin )
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
DEFAULT_SD1_FACTOR = 2;
DEFAULT_SD2_FACTOR = 3;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rri', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('sd1_factor', DEFAULT_SD1_FACTOR, @isnumeric);
p.addParameter('sd2_factor', DEFAULT_SD2_FACTOR, @isnumeric);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rri, varargin{:});
sd1_factor = p.Results.sd1_factor;
sd2_factor = p.Results.sd2_factor;
should_plot = p.Results.plot;

% Normalize input shape
rri = reshape(rri, 1, length(rri));

%% Rotate input
alpha = -pi/4;

% Original data x-y pairs
x_old = rri(1:end-1);   % RR(n)
y_old = rri(2:end);     % RR(n+1)

% Rotate the data to the new coordinate system
rri_rotated = rotation_matrix(alpha) * [x_old; y_old];
x_new = rri_rotated(1,:);
y_new = rri_rotated(2,:);

% Calculate standard deviation along the new axes
sd1 = sqrt(var(y_new));
sd2 = sqrt(var(x_new));

%% Fit ellipse

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

%% Find outliers
% Use ellipse cannonical equation to find all points outside the ellipse
outlier_idx_logical = (x_new - c_x).^2 / r_x^2 + (y_new - c_y).^2 / r_y^2 > 1;

% Since the original input vector is longer by 1, we need to append another value
outlier_idx_logical = [outlier_idx_logical, false];

% Convert logical indeices to regular
outlier_idx = find(outlier_idx_logical);

%% Lines for ellipse axes
ellipse_center_new = [c_x; c_y];

% Create the lines in the new coordinate system
sd1_line_new = [0, 0; -sd1, sd1] + [ellipse_center_new, ellipse_center_new];
sd2_line_new = [-sd2, sd2; 0, 0] + [ellipse_center_new, ellipse_center_new];

% Rotate back to the old system
sd1_line_old = rotation_matrix(-alpha) * sd1_line_new;
sd2_line_old = rotation_matrix(-alpha) * sd2_line_new;

%% Plotting
if (should_plot)
    msz = 4; lw1 = 1.5; lw2 = 3;
    figure; hold on; axis equal tight; grid on;
    xlabel('RR(n) [sec]'); ylabel('RR(n+1) [sec]');

    plot(x_old, y_old, 'b+', 'MarkerSize', msz);
    plot(x_old(outlier_idx), y_old(outlier_idx), 'ro', 'MarkerSize', msz*1.25);
    plot(ellipse_old(1,:), ellipse_old(2,:), 'k--', 'LineWidth', lw1);
    plot(sd1_line_old(1,:), sd1_line_old(2,:), 'r-', 'LineWidth', lw2);
    plot(sd2_line_old(1,:), sd2_line_old(2,:), 'g-', 'LineWidth', lw2);
    legend({'RR intervals', 'Outliers', 'Ellipse fit', sprintf('SD1=%.4f', sd1), sprintf('SD2=%.4f', sd2)}, 'Location', 'southeast');
end

%% Helper functions

% Creates a 2D rotation matrix
function rotation_mat = rotation_matrix(theta)
    rotation_mat = [cos(theta), -sin(theta); sin(theta), cos(theta)];
end

end

