function [ hrv_nl ] = hrv_nonlinear( nni, tm_nni, varargin )
%HRV_NONLINEAR Calcualte non-linear HRV metrics
%   Detailed explanation goes here

%% === Input

%% === DFA

% Integrate the NN intervals and remove mean
nni_int = cumsum(nni - mean(nni));

N = length(nni_int);
num_win = 1; % current number of windows
DFA_Fn = ones(N, 1) * NaN;

while 1
    % Calculate n, the number of samples in each window
    n = floor(N / num_win);
    
    % Stop iterating if too few samples per window
    if n < 4; break; end
    
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
    DFA_Fn(n) = sqrt ( 1/N * sum((nni_windows(:) - nni_regressed(:)).^2) ) ;
    
    % Increment number of windows for next iteration
    num_win = num_win + 1;
end

% Find the indices of all the DFA values we calculated
dfa_idx = find(~isnan(DFA_Fn));
DFA_n  = (1:N)';
DFA_Fn = DFA_Fn(dfa_idx);
DFA_n  = DFA_n(dfa_idx);

DFA_fit = polyfit(log(DFA_n), log(DFA_Fn), 1)

%% === Display output if no output args
if (nargout == 0)
    figure; 
    loglog(DFA_n, DFA_Fn, 'rx'); hold on;
    % plot(DFA_n, 10.^(DFA_fit(2) + DFA_fit(1)*log(DFA_n)), 'b--');
    
    grid on; xlabel('log_{10}(n)'); ylabel('log_{10}(F(n))');
end
