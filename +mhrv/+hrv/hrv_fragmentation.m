function [ hrv_frag ] = hrv_fragmentation( nni, varargin )
%Computes HRV fragmentation indices [1]_ of a NN interval time series.
%
%:param nni: Vector of NN-interval dirations (in seconds)
%
%:returns: Table containing the following fragmentation metrics:
%
%    - PIP: Percentage of inflection points.
%    - IALS: Inverse average length of segments.
%    - PSS: Percentage of NN intervals that are in short segments.
%    - PAS: Percentage of NN intervals that are in alternation segments of at least 4 intervals.
%
%.. [1] Costa, M. D., Davis, R. B., & Goldberger, A. L. (2017). Heart Rate
%   Fragmentation: A New Approach to the Analysis of Cardiac Interbeat Interval
%   Dynamics. Frontiers in Physiology, 8(May), 1–13.
%

import mhrv.defaults.*;

%% Input

% Define input
p = inputParser;
p.addRequired('nni', @(x) ~isempty(x) && isvector(x));

% Get input
p.parse(nni, varargin{:});

%% Calculate fragmentation indices

% Number of NN intervals
N = length(nni);

% Reshape input into a row vector
nni = reshape(nni, [1, N]);

% delta NNi: differences of consecutinve NN intervals
dnni = diff(nni);

% Product of consecutive NN interval differences
ddnni = dnni(1:end-1) .* dnni(2:end);

% Logical vector of inflection point locations (zero crossings). Add a fake inflection points at the
% beginning and end so that we can count the first and last segments (i.e. we want these segments
% to be surrounded by inflection points like regular segments are).
ip = [-1, ddnni, -1] < 0;

% Number of inflection points (where detla NNi changes sign). Subtract 2 for the fake points we
% added.
nip = nnz(ip) - 2;

% Percentage of inflection points (PIP)
pip = nip / N;

% Indices of inflection points
ip_idx = find(ip);

% Length of acceleration/deceleration segments: the difference between inflection point indices
% is the length of the segments. This includes the first and last segment because of the fake points
% we added.
segment_lengths = diff(ip_idx);

% Inverse Average Length of Segments (IALS)
ials = 1 / mean(segment_lengths);

% Number of NN intervals in segments with less than three intervals
short_segment_lengths = segment_lengths(segment_lengths < 3);
nss = sum(short_segment_lengths);

% Percentage of NN intervals that are in short segments (PSS)
pss = nss / N;

% An alternation segment is a segment of length 1
alternation_segment_boundaries = [1, segment_lengths > 1, 1];
alternation_segment_lengths = diff(find(alternation_segment_boundaries));

% Percentage of NN intervals in alternation segments length > 3 (PAS)
nas = sum(alternation_segment_lengths(alternation_segment_lengths > 3));
pas = nas / N;

%% Create metrics table
hrv_frag = table;
hrv_frag.Properties.Description = 'Fragmentation HRV metrics';

hrv_frag.PIP = pip * 100;
hrv_frag.Properties.VariableUnits{'PIP'} = '%';
hrv_frag.Properties.VariableDescriptions{'PIP'} = 'Percentage of inflection points in the NN interval time series';

hrv_frag.IALS = ials;
hrv_frag.Properties.VariableUnits{'IALS'} = 'n.u.';
hrv_frag.Properties.VariableDescriptions{'IALS'} = 'Inverse average length of the acceleration/deceleration segments';

hrv_frag.PSS = pss * 100;
hrv_frag.Properties.VariableUnits{'PSS'} = '%';
hrv_frag.Properties.VariableDescriptions{'PSS'} = 'Percentage of short segments';

hrv_frag.PAS = pas * 100;
hrv_frag.Properties.VariableUnits{'PAS'} = '%';
hrv_frag.Properties.VariableDescriptions{'PAS'} = 'The percentage of NN intervals in alternation segments';
end

