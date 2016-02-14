function [ hrv_td, hrv_fd ] = rhrv( rec_name, varargin )
%RHRV Heart Rate Variability metrics
%   Detailed explanation goes here

%% === Input

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);

% Get input
p.parse(rec_name, varargin{:});

%% === Calculate NN intervals
[ nni, tnn, rri, trr ] = ecgnn(rec_name, 'gqpost', true);

%% === Pre process intervals to remove outliers
[ tnn_filtered, nni_filtered ] = filternn(tnn, nni);

%% === Time Domain
hrv_td = hrv_time(nni_filtered);

%% === Freq domain
[ hrv_fd, pxx_lomb, f_lomb ] = hrv_freq(nni_filtered, tnn_filtered, 'method', 'lomb');

%% === Display output if no output args
if (nargout == 0)
    % Calculate with AR method to plot both
    [ ~, pxx_ar, ~ ] = hrv_freq(nni_filtered, tnn_filtered, 'method', 'ar');

    % Plot RR and Spectrum
    close all;
    set(0,'DefaultAxesFontSize',14);
    figure;
    subplot(2,1,1); plot(tnn_filtered, nni_filtered);
    xlabel('Time [s]'); ylabel('NN-interval [s]');
    subplot(2,1,2); semilogy(f_lomb, [pxx_lomb, pxx_ar]); grid on; hold on;
    xlabel('Frequency [hz]'); ylabel('Power Density [s^2/Hz]');
    
    % vertical lines
    f_max = 0.4;
    LF_band = [0.04, 0.15];
    HF_band = [0.15, f_max];
    yrange = get(gca,'ylim');
    line(LF_band(1) * ones(1,2), yrange, 'LineStyle', ':', 'Color', 'red');
    line(HF_band(1) * ones(1,2), yrange, 'LineStyle', ':', 'Color', 'red');
    line(HF_band(2) * ones(1,2), yrange, 'LineStyle', ':', 'Color', 'red');
    xlim([0,f_max*1.01]); ylim([1e-7, 1]);
    
    disp(hrv_td);
    disp(hrv_fd);
end
