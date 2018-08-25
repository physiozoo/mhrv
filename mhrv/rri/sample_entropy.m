function sampen = sample_entropy(sig, m, r)
%Calculate sample entropy [3]_ (SampEn) of a signal. Sample entropy is a measure of
%the irregularity of a signal.
%
%:param sig: The input signal.
%:param m: Template length in samples.
%:param r: Threshold for matching sample values.
%
%:returns: The sample entropy value of the input signal.
%
%.. [3] Richman, J. S., & Moorman, J. R. (2000).  ‘Physiological time-series
%   analysis using approximate entropy and sample entropy.’  American Journal of
%   Physiology. Heart and Circulatory Physiology, 278(6), H2039?H2049.
%

N = length(sig);

% Validations
if (m < 0 || r < 0)
    error('Invalid parameter values');
end

% Initialize template-match counters. A is the number of template matches
% of length m+1, and B is the number of template matches of length m.
A = 0; B = 0;
if m == 0
    % When m=0, B is defined as N*(N-1)/2.
    B = N * (N-1) / 2;
end

% Convert to single for speed, since this algorithm requires alot of
% in-memory copying
sig = single(sig);

% Create a matrix containing all templates (windows) of length m+1 (with m
% samples overlap) that exist in the signal. Each row is a window.
templates_mat = transpose( buffer(sig, m+1, m, 'nodelay') );
num_templates = size(templates_mat, 1);

next_templates_mat_m = templates_mat(:,1:m);
next_templates_mat_1 = templates_mat(:,m+1);
clear templates_mat;

% Loop over all templates, calcualting the Chebyshev distance between the
% current template and all the following templates.
for win_idx = 1:num_templates
    % Extract the current template and all the templates following it.
    curr_template_m = next_templates_mat_m(1,:);
    next_templates_mat_m = next_templates_mat_m(2:end,:);
    curr_template_1 = next_templates_mat_1(1,:);
    next_templates_mat_1 = next_templates_mat_1(2:end,:);

    % Calculate absolute difference vectors between the current template and the
    % each of the next templates.
    diff_m = abs( next_templates_mat_m - curr_template_m );
    diff_1 = abs( next_templates_mat_1 - curr_template_1 );

    % Calculate Chebyshev distance: This is the max component of the absolute
    % difference vector. We'll calculate two distances:
    % dist_B: the Chebyshev distance using only the first m components.
    dist_B = max(diff_m, [], 2); % max val of each row in diff_m.

    % dist_A: the max difference component (Chebyshev distance) using all m+1 components
    if m ~= 0
        % max between column m+1 and dist_B (which is the max of columns 1..m)
        dist_A = max(dist_B, diff_1);

        % A template match is a case where the Chebyshev distance between the
        % current template and one of the next templates is less than r. Count
        % the number of matches of length m+1 and of length m we have, and
        % increment the appropriate counters.
        A = A + nnz(dist_A < r);
        B = B + nnz(dist_B < r);
    else
        % In case m is zero, dist_B is empty and dist_A is simply the diff_mat.
        A = A + nnz(diff_1 < r);
    end
end

% Calculate the sample entropy value based on the number of template matches.
sampen = -log(A / B);
end

