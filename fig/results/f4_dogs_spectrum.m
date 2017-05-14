close all;
output_dir = ['fig' filesep 'out'];

folder = 'db/billman/';
rec_types = {'pre-*-bsl', 'pre-*-dbk'};

% Load canine parameters
rhrv_load_params('canine');

for rec_type_idx = 1:length(rec_types)
    files = dir([folder sprintf('*%s.dat', rec_types{rec_type_idx})])';
    nfiles = length(files);

    for file_idx = 1:nfiles
        file = files(file_idx);
        [path, name, ext] = fileparts([folder file.name]);
        rec_name = [path filesep name];

        % Read data from record
        fprintf('-> Reading from %s\n', rec_name);

        [rri, trr] = ecgrr(rec_name, 'plot', false);
        [nni, tnn] = filtrr(rri, trr);

        % Calculate spectrum
        [hrv_fd, pxx, f_axis, plot_data] = hrv_freq(nni);

        % Plots
        fig = figure('Name', [name ' ' plot_data.name]); ax = gca;
        plot_hrv_freq_spectrum(ax, plot_data, 'ylim', [1e-7, 1e-0]);

        % Add Peaks
        plot(ax, hrv_fd.LF_PEAK, pxx(f_axis==hrv_fd.LF_PEAK).*1.25, 'bv', 'MarkerSize', 8, 'MarkerFaceColor', 'blue', 'DisplayName', num2str(hrv_fd.LF_PEAK));
        plot(ax, hrv_fd.HF_PEAK, pxx(f_axis==hrv_fd.HF_PEAK).*1.25, 'rv', 'MarkerSize', 8, 'MarkerFaceColor', 'red', 'DisplayName',  num2str(hrv_fd.HF_PEAK));

        % Print the figure
        fig_print(fig, [output_dir filesep name '_freq'], 'title', rec_name);
        delete(fig);

        % Write RR-intervals lengths
        % dlmwrite([output_dir filesep name '_nn.txt'], nni, 'delimiter', '\n', 'precision','%.3f');
    end

end