function [ chan ] = get_signal_channel( rec_name, sig_desc )
%GET_SIGNAL_CHANNEL Find the channel of a signal in the record matching a description

% default value if we can't find the description
chan = [];

% regex for comment line in the header file
comment_regex = '^\s*#.*';

fheader = fopen([rec_name, '.hea']);

i = 1;
first_line = true; % first non-comment line is the 'record line', we need to skip it
line = fgetl(fheader);
while ischar(line)
    
    % if line is not a comment line, test it
    if (isempty(regexpi(line, comment_regex)))
        
        % Skip the first non-comment line because it's the 'record line'
        if first_line
            first_line = false;
        else
            
            % if line matches the description (partial match), return it's index
            if (~isempty(regexpi(line, sig_desc)))
                chan = i;
                break;
            else
                i = i+1;
            end
        end
    end
    
    line = fgetl(fheader);
end

fclose(fheader);

end

