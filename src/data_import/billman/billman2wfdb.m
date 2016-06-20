function files = billman2wfdb(input_path, output_rec_prefix)
%BILLMAN 2WFDB Convert records from Billman's 2013 study to wfdb format.
%   input_path: Folder continaing files in *.acq format.
%   output_rec_prefix: folder and prefix record name to use for the output
%   files. Example: if  output_rec_prefix='db/billman/2013/canine' then
%   output file records might be 'db/billman/2013/01-int',
%   'db/billman/2013/01-dbk'...

% Create output folder
[out_path,rec_name,~] = fileparts(output_rec_prefix);
if (~exist(out_path, 'dir'))
    mkdir(out_path);
end

% Load input files
files = dir([input_path '*.acq']);

for ii = 1:length(files)
    [t, data, fs, info] = read_acq([input_path files(ii).name]);
    if (isempty(info.szText)); info.szText = {}; end
    
    % Find the channel with ECG data
    ecg_channel = 0;
    for jj = 1:length(data)
        if (~isempty(regexp(info.szCommentText{jj}, 'ecg', 'ignorecase')))
            ecg_channel = jj;
        end
    end
    if (ecg_channel == 0)
        warn(['No ECG channel found for file ', files(ii).name, ', skipping...']);
        continue;
    end
    
    % Save the ecg_channel number into the result structure
    files(ii).ecg_channel = ecg_channel;
    
    atropine_segment = 0; propranolol_segment  = 0;
    % Go over segment labels to find if and when atropine and propranolol were administered
    for jj = 1:length(info.szText)
        label_text = info.szText{jj};

        % look for matches in the label text (take into account the spelling mistakes that exist in the files...
        if (atropine_segment == 0 && ~isempty(regexpi(label_text, 'atropine|atopine')))
            atropine_segment = jj;
        end
        if (propranolol_segment == 0 && ~isempty(regexpi(label_text, 'propranolol|prorpanolol|proprnaolol')))
            propranolol_segment = jj;
        end
        
        % If both are found, take the first data segment (intrinsic), and the current data segment
        % (which has both atropine and propranolol). However make sure one of the segments immediately
        % follows the other.
        if (atropine_segment > 0 && propranolol_segment > 0 && abs(propranolol_segment - atropine_segment) == 1)
            
            % Get intrinsic data indices: This is all the data until the second marker.
            % Add 1 because the indices in the file start from zero
            idx_intrinsic_low = 1;
            idx_intrinsic_high = 1 + double(info.lSample(2));
            
            % Get double-blockade data indices: This is the data from the segment with both atropine and propranolol
            % until the next segment (if exists) or until end of data.
            % Add 1 because the indices in the file start from zero.
            max_seg = max([atropine_segment, propranolol_segment]);
            idx_blockade_low = 1 + double(info.lSample(max_seg));
            if (max_seg == length(info.szText))
                idx_blockade_high = length(t{ecg_channel});
            else
                idx_blockade_high = 1 + double(info.lSample(max_seg+1));
            end
            
            fprintf('#%02d. %s: [%d~%d], [%d~%d] - %s\n', ii, files(ii).name,...
                idx_intrinsic_low, idx_intrinsic_high, idx_blockade_low, idx_blockade_high,...
                strjoin(info.szText, ', '));

            % Write result files
            output_rec = sprintf('%s/%s%02d', out_path, rec_name, ii);
            write_record(output_rec, data,...
                         idx_intrinsic_low:idx_intrinsic_high, idx_blockade_low:idx_blockade_high,...
                         fs, info);
            
            % Skip next segments for this file
            break;
        end
    end
end

    % Helper function to write the data to file
    function write_record(output_rec, data, intrinsic_idx, blockade_idx, fs, info)
            %mat2wfdb(data_intrinsic, [output_rec num2str(ii) '-int'], fs, [], );
            
            % Extract intrinsic and blockade segments
            data_mat = cell2mat(data);
            data_intrinsic = data_mat(intrinsic_idx, :);
            data_blockade  = data_mat(blockade_idx,  :);

            % Handle units
            units = cell(1, size(data_mat,2));
            for kk = 1:size(data_mat,2)
                units_text = info.szUnitsText{kk};
                % Convert volts to mV (default physionet units)
                if (~isempty(regexpi(units_text, '^volt|^V$')))
                    data_mat(:, kk) = data_mat(:, kk) * 1000;
                    units_text = 'mV';
                end
                % Remove whitespace from units
                units{kk} = strrep(units_text, ' ', '');
            end
            
            % Write to wfdb file format
            file_comment = ['Original filename: ' files(ii).name];
            channel_comments = info.szCommentText;
            mat2wfdb(data_intrinsic, [output_rec, '-int'], fs, [], units, file_comment, [], channel_comments);
            mat2wfdb(data_blockade,  [output_rec, '-dbk'], fs, [], units, file_comment, [], channel_comments);
    end
end