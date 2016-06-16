function files = billman(folder)

files = dir([folder '*.acq']);

for ii = 1:length(files)
    [t, data, fs, info] = read_acq([folder files(ii).name]);
    if (isempty(info.szText)); info.szText = {}; end
    %fprintf('#%02d. %s: %s\n', ii, files(ii).name, strjoin(info.szText, ', '));
    
    % Add the data to the results structure
    files(ii).t = t;
    files(ii).data = data;
    files(ii).fs = fs;

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
        if (atropine_segment == 0 && ~isempty(regexp(label_text, 'atropine|atopine', 'ignorecase')))
            atropine_segment = jj;
        end
        if (propranolol_segment == 0 && ~isempty(regexp(label_text, 'propranolol|prorpanolol|proprnaolol', 'ignorecase')))
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

            % Update the result structure
            files(ii).idx_intrinsic_low = idx_intrinsic_low;
            files(ii).idx_intrinsic_high = idx_intrinsic_high;
            files(ii).idx_blockade_low = idx_blockade_low;
            files(ii).idx_blockade_high = idx_blockade_high;
            
            % Skip next segments for this file
            break;
        end
    end
end
end