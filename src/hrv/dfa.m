function [ n, fn, alpha ] = dfa( t, sig, varargin )
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

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('t', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('sig', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('n_min',  DEFAULT_NMIN, @(x) isnumeric(x) && isscalar(x));
p.addParameter('n_max',  DEFAULT_NMAX, @(x) isnumeric(x) && isscalar(x));
p.addParameter('n_incr',  DEFAULT_N_INCR, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(t, sig, varargin{:});
n_min = p.Results.n_min;
n_max = p.Results.n_max;
n_incr = p.Results.n_incr;
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

fn_log = log10(fn);
n_log = log10(n);

% Fit a line to the log-log function
fit_params = polyfit(n_log, fn_log, 1);

% take the slope of the line
alpha = fit_params(1);
intercept = fit_params(2);

%% Plot
if should_plot
    figure;
    loglog(n, fn, 'ko', 'MarkerSize', 6);
    
    grid on; hold on; axis tight;
    xlabel('Block size (n)'); ylabel('log_{10}(F(n))');
    set(gca, 'XTick', [4, 8, 16, 32, 64, 128]);
    
    % Plot alpha line
    alpha_line = alpha * n_log + intercept;
    loglog(10.^n_log, 10.^alpha_line, 'Color', 'blue', 'LineStyle', '--', 'LineWidth', 3);
    
    legend('DFA', sprintf('alpha=%.3f', alpha), 'Location', 'northwest');
end

end

