function [ hrv_nl ] = hrv_nonlinear( nni, tm_nni, varargin )
%HRV_NONLINEAR Calcualte non-linear HRV metrics
%   Detailed explanation goes here

%% === Input
DEFAULT_ALPHA1_RANGE = [4, 16];
DEFAULT_ALPHA2_RANGE = [32, 128];
DEFAULT_NMIN = 3;
DEFAULT_NMAX = 150;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('nni', @(x) isnumeric(x) && ~isscalar(x));
p.addRequired('tm_nni', @(x) isnumeric(x) && ~isscalar(x));
p.addParameter('alpha1_range',  DEFAULT_ALPHA1_RANGE, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('alpha2_range',  DEFAULT_ALPHA2_RANGE, @(x) isnumeric(x) && numel(x) == 2);
p.addParameter('n_min',  DEFAULT_NMIN, @(x) isnumeric(x) && isscalar(x));
p.addParameter('n_max',  DEFAULT_NMAX, @(x) isnumeric(x) && isscalar(x));
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(nni, tm_nni, varargin{:});
alpha1_range = p.Results.alpha1_range;
alpha2_range = p.Results.alpha2_range;
n_min = p.Results.n_min;
n_max = p.Results.n_max;
should_plot = p.Results.plot;

%% === DFA

% Integrate the NN intervals without mean
nni_int = cumsum(nni - mean(nni));

N = length(nni_int);
DFA_Fn = ones(n_max, 1) * NaN;

for n = n_min:n_max
    % Calculate the number of windows we need for the current n
    num_win = floor(N/n);

    % Break the signal into num_win windows of n samples each
    nni_windows = reshape(nni_int(1:n*num_win), n, num_win);
    tm_windows  = reshape(tm_nni(1:n*num_win), n, num_win);
    nni_regressed = zeros(size(nni_windows));
    
    % Perform linear regression in each window
    for ii = 1:num_win
        y = nni_windows(:, ii);
        x = [ones(n, 1), tm_windows(:, ii)];
        b = x\y;
        yn = x * b;
        nni_regressed(:, ii) = yn;
    end
    
    % Calculate F(n), the value of the DFA for the current n
    DFA_Fn(n) = sqrt ( 1/N * sum((nni_windows(:) - nni_regressed(:)).^2) );
end

% Find the indices of all the DFA values we calculated
DFA_Fn = DFA_Fn(n_min:n_max);
DFA_n  = (n_min:n_max)';

%% === Nonlinear metrics (short and long-term scaling exponent)

alpha1_idx = find(DFA_n >= alpha1_range(1) & DFA_n <= alpha1_range(2));
alpha2_idx = find(DFA_n >= alpha2_range(1) & DFA_n <= alpha2_range(2));

DFA_Fn_log = log10(DFA_Fn);
DFA_n_log = log10(DFA_n);

DFA_fit_alpha1 = polyfit(DFA_n_log(alpha1_idx), DFA_Fn_log(alpha1_idx), 1);
DFA_fit_alpha2 = polyfit(DFA_n_log(alpha2_idx), DFA_Fn_log(alpha2_idx), 1);

alpha1_line = DFA_fit_alpha1(1) * DFA_n_log(alpha1_idx) + DFA_fit_alpha1(2);
alpha2_line = DFA_fit_alpha2(1) * DFA_n_log(alpha2_idx) + DFA_fit_alpha2(2);

hrv_nl = struct;
hrv_nl.alpha1 = DFA_fit_alpha1(1);
hrv_nl.alpha2 = DFA_fit_alpha2(1);

%% === Display output if requested
if (should_plot)
    set(0,'DefaultAxesFontSize',14);
    lw = 4.0;
    figure; 

    % Plot the DFA data
    loglog(DFA_n, DFA_Fn, 'ko'); hold on; grid on;

    % Plot alpha1 line
    loglog(10.^DFA_n_log(alpha1_idx), 10.^alpha1_line, 'Color', 'blue', 'LineStyle', '--', 'LineWidth', lw);

    % Plot alpha2 line
    loglog(10.^DFA_n_log(alpha2_idx), 10.^alpha2_line, 'Color', 'red', 'LineStyle', '--', 'LineWidth', lw);

    xlabel('Block size (n)'); ylabel('log_{10}(F(n))');
    legend('DFA', ['\alpha_1=' num2str(hrv_nl.alpha1)], ['\alpha_2=' num2str(hrv_nl.alpha2)]);
    set(gca, 'XTick', [4, 8, 16, 32, 64, 128]);
end
