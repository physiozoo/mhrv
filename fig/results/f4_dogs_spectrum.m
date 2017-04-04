close all;
output_dir = ['fig' filesep 'out'];

folder = 'db/billman/';
rec_types = {'pre-*-bsl'};

for rec_type_idx = 1:length(rec_types);
    files = dir([folder sprintf('*-%s.dat', rec_types{rec_type_idx})])';
    nfiles = length(files);

    for file_idx = 1:nfiles
        file = files(file_idx);
        [path, name, ext] = fileparts([folder file.name]);
        rec_name = [path '/' name];
        
        % Read data from record
        fprintf('-> Reading from %s\n', rec_name);
        [nni, tnn, ~, ~] = ecgnn(rec_name, 'plot', false, 'filter_gqpost', false, ...
                                 'gqconf', 'cfg/gqrs.billman.conf', ...
                                 'filter_lowpass', true, 'filter_poincare', true);
       
        % Calculate spectrum
        hrv_freq(nni, tnn, 'plot', true, 'window_minutes', [], 'band_factor', 120/75);
        
        % Print the figure
        fig_print(gcf, [output_dir filesep 'freq_' name], 'title', rec_name);
    end

end