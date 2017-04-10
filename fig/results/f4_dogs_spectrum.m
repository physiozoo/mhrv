close all;
output_dir = ['fig' filesep 'out'];

folder = 'db/billman/';
rec_types = {'pre-*-bsl'};

% Load canine parameters
rhrv_load_params('rhrv_params_canine');

for rec_type_idx = 1:length(rec_types);
    files = dir([folder sprintf('*%s.dat', rec_types{rec_type_idx})])';
    nfiles = length(files);

    for file_idx = 1:nfiles
        file = files(file_idx);
        [path, name, ext] = fileparts([folder file.name]);
        rec_name = [path '/' name];
        
        % Read data from record
        fprintf('-> Reading from %s\n', rec_name);
        [nni, tnn, ~, ~] = ecgnn(rec_name, 'plot', false);
       
        % Calculate spectrum
        hrv_freq(nni, tnn, 'plot', true);
        
        % Print the figure
        fig_print(gcf, [output_dir filesep name '_freq'], 'title', rec_name);

        % Write RR-intervals lengths
        dlmwrite([output_dir filesep name '_nn.txt'], nni, 'delimiter', '\n', 'precision','%.3f');
    end

end