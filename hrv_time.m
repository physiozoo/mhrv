function [ hrv_td ] = hrv_time( rri )
%HRV_TIME Calculate time-domain HRV mertics from RR intervals
%   Detailed explanation goes here

hrv_td = struct;

%% === Time Domain Metrics
hrv_td.AVNN = mean(rri);
hrv_td.SDNN = sqrt(var(rri));
hrv_td.RMSSD = sqrt(mean(diff(rri).^2));
hrv_td.pNN50 = sum(abs(diff(rri)) > 0.05)/(length(rri)-1);

end

