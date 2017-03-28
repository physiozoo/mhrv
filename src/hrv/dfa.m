function [ n, fn, alpha1, alpha2 ] = dfa( t, sig, varargin )
%DFA Detrended fluctuation analysis
%   Calculates the DFA of a signal and it's scaling exponent alpha.
%   Input:
%       - t: time (or x values of signal)
%       - sig: signal data (or y values of signal)
%       - varargin: Pass in name-value pairs to configure advanced options:
%           - n_min: Minimal DFA block-size (default 4)
%           - n_max: Maximal DFA block-size (default 128)
%           - n_incr: Increment value for n (default 4)
%   Output:
%       - n: block sizes (x-axis of DFA)
%       - fn: DFA value for each block size n
%       - alpha: Exponential scaling factor

%% === Input
DEFAULT_NMIN = 4;
DEFAULT_NMAX = 128;
DEFAULT_N_INCR = 4;
DEFAULT_ALPHA1_RANGE = [4, 15];
DEFAULT_ALPHA2_RANGE = [16, 128];

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('t', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('sig', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('n_min',  DEFAULT_NMIN, @(x) isnumeric(x) && isscalar(x));
p.addParameter('n_max',  DEFAULT_NMAX, @(x) isnumeric(x) && isscalar(x));
p.addParameter('n_incr',  DEFAULT_N_INCR, @(x) isnumeric(x) && isscalar(x));
p.addParameter('alpha1_range',  DEFAULT_ALPHA1_RANGE, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('alpha2_range',  DEFAULT_ALPHA2_RANGE, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(t, sig, varargin{:});
n_min = p.Results.n_min;
n_max = p.Results.n_max;
n_incr = p.Results.n_incr;
alpha1_range = p.Results.alpha1_range;
alpha2_range = p.Results.alpha2_range;
should_plot = p.Results.plot;

%% === DFA

% Integrate the signal without mean
nni_int = cumsum(sig - mean(sig));

N = length(nni_int);

fn = ones(n_max, 1) * NaN;
n = n_min:n_incr:n_max;

for nn = n
    % Calculate the number of windows we need for the current n
    num_win = floor(N/nn);

    % Break the signal into num_win windows of n samples each
    sig_windows = reshape(nni_int(1:nn*num_win), nn, num_win);
    t_windows  = reshape(t(1:nn*num_win), nn, num_win);
    sig_regressed = zeros(size(sig_windows));

    % Perform linear regression in each window
    for ii = 1:num_win
        y = sig_windows(:, ii);
        x = [ones(nn, 1), t_windows(:, ii)];
        b = x\y;
        yn = x * b;
        sig_regressed(:, ii) = yn;
    end

    % Calculate F(n), the value of the DFA for the current n
    fn(nn) = sqrt ( 1/N * sum((sig_windows(:) - sig_regressed(:)).^2) );
end

% Find the indices of all the DFA values we calculated
fn = fn(n);
n  = n';

%% === Scaling exponent, alpha

% Find DFA values in each of the alpha ranges
alpha1_idx = find(n >= alpha1_range(1) & n <= alpha1_range(2));
alpha2_idx = find(n >= alpha2_range(1) & n <= alpha2_range(2));

% Fit a line to the log-log DFA in each alpha range
fn_log = log10(fn);
n_log = log10(n);
fit_alpha1 = polyfit(n_log(alpha1_idx), fn_log(alpha1_idx), 1);
fit_alpha2 = polyfit(n_log(alpha2_idx), fn_log(alpha2_idx), 1);

% Save the slopes of the lines
alpha1 = fit_alpha1(1);
alpha2 = fit_alpha2(1);

%% Plot
if should_plot
    lw = 3.8; ls = ':';
    
    figure;
    h1 = loglog(n, fn, 'ko', 'MarkerSize', 7);
    hold on; grid on; axis tight;

    % Plot alpha1 line
    alpha1_line = fit_alpha1(1) * n_log(alpha1_idx) + fit_alpha1(2);
    loglog(10.^n_log(alpha1_idx), 10.^alpha1_line, 'Color', 'blue', 'LineStyle', ls, 'LineWidth', lw);

    % Plot alpha2 line
    alpha2_line = fit_alpha2(1) * n_log(alpha2_idx) + fit_alpha2(2);
    loglog(10.^n_log(alpha2_idx), 10.^alpha2_line, 'Color', 'red', 'LineStyle', ls, 'LineWidth', lw);

    xlabel('log(n)'); ylabel('log(F(n))');
    legend('DFA', ['\alpha_1 = ' num2str(alpha1)], ['\alpha_2 = ' num2str(alpha2)], 'Location', 'northwest');
    set(gca, 'XTick', [4, 8, 16, 32, 64, 128]);
    uistack(h1, 'top');
end

end

