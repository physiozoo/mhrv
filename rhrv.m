function [ hrv_td, hrv_fd ] = rhrv( rec_name, varargin )
%RHRV Heart Rate Variability metrics
%   Detailed explanation goes here

%% === Input
close all;

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('plot', nargout == 0, @islogical);

% Get input
p.parse(rec_name, varargin{:});
should_plot = p.Results.plot;

%% === Calculate NN intervals
[ nni, tnn, rri, trr ] = ecgnn(rec_name, 'gqpost', true);

%% === Pre process intervals to remove outliers
[ tnn_filtered, nni_filtered ] = filternn(tnn, nni, 'plot', should_plot);


%% === Non linear
[hrv_nl] = hrv_nonlinear(nni_filtered, tnn_filtered, 'plot', should_plot);

%% === Time Domain
hrv_td = hrv_time(nni_filtered);
hrv_td.NN_RR = length(nni_filtered)/length(rri);

%% === Freq domain
[ hrv_fd, pxx_lomb, f_lomb ] = hrv_freq(nni_filtered, tnn_filtered, 'method', 'lomb', 'plot', should_plot);

%% === Display output if no output args
if (nargout == 0)   
    % Print HRV metrics to user
    disp(hrv_td);
    disp(hrv_fd);
    disp(hrv_nl);
end
