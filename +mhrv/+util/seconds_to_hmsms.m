function hmsms = seconds_to_hmsms(t_seconds)
    hmsms = struct;
    hmsms.h  = mod(floor(t_seconds / 3600), 60);
    hmsms.m  = mod(floor(t_seconds / 60), 60);
    hmsms.s  = mod(floor(t_seconds), 60);
    hmsms.ms = floor(mod(t_seconds, 1)*1000);
end

