close all;
output_dir = ['fig' filesep 'out'];

folder = 'db/billman/';
rec_types = {'pre-*-bsl', 'post-*-bsl', 'pre-*-dbk', 'post-*-dbk'};
rec_types_full = {'Basal pre-ex', 'Basal post-ex', 'Double Blockade pre-ex', 'Double Blockade post-ex'};

for rec_type_idx = 1:length(rec_types);
    files = dir([folder sprintf('*-%s.dat', rec_types{rec_type_idx})])';
    nfiles = length(files);
    all_hr = cell(nfiles,1);
    
    % Aggregate all HR data into a cell array
    for file_idx = 1:nfiles
        file = files(file_idx);
        [path, name, ext] = fileparts([folder file.name]);
        rec_name = [path '/' name];
        
        % Read HR data from record (channel 2)
        fprintf('-> Reading from %s\n', rec_name);
        [~, curr_hr, ~] = rdsamp(rec_name, 2);
        
        all_hr{file_idx} = curr_hr;
    end
    
    % Concatenate all HR data to a single vector
    all_hr_vec = cell2mat(all_hr);
    
    all_hr_mean = mean(all_hr_vec);
    all_hr_std = std(all_hr_vec);
    
    fh = figure;
    h = histogram(all_hr_vec, 0:250, 'Normalization','probability');
    xlabel('Heart Rate [BPM]'); ylabel('Probability');
    
    line(ones(1,2)*all_hr_mean, ylim, 'LineStyle', '-', 'Color', 'red', 'LineWidth', 2.5);
    line(ones(1,2)*(all_hr_mean + all_hr_std), ylim, 'LineStyle', ':', 'Color', 'red', 'LineWidth', 2);
    line(ones(1,2)*(all_hr_mean - all_hr_std), ylim, 'LineStyle', ':', 'Color', 'red', 'LineWidth', 2);
    
    legend({'HR Probability', sprintf('mean = %.1f', all_hr_mean), sprintf('st. dev = %.1f', all_hr_std)});
    title(rec_types_full{rec_type_idx});
end

% Print out first figure only
fig_print(1, [output_dir filesep 'billman_basal_pre_ex_hr_hist']);