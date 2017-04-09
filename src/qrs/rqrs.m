function [ qrs, outliers ] = rqrs( rec_name, varargin )
%RQRS R-peak detection in ECG signals, based on 'gqrs' and 'gqpost'.
%   RQRS Finds R-peaks in PhysioNet-format ECG records. It uses the 'gqrs' and 'gqpost' programs
%   from the PhysioNet WFDB toolbox, to find the QRS complexes. Then, it searches forward in a small
%   window to find the R-peak.

%% === Input

% Defaults
DEFAULT_GQPOST = rhrv_default('rqrs.use_gqpost', true);
DEFAULT_GQCONF = rhrv_default('rqrs.gqconf', '');
DEFAULT_WINDOW_SIZE_SECONDS = rhrv_default('rqrs.window_size_sec', 0.056); % 80% of .07, the average human QRS duration

% Define input
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('rec_name', @isrecord);
p.addParameter('gqpost', DEFAULT_GQPOST, @(x) islogical(x) && isscalar(x));
p.addParameter('gqconf', DEFAULT_GQCONF, @isstr);
p.addParameter('window_size_sec', DEFAULT_WINDOW_SIZE_SECONDS, @isnumeric);

% Get input
p.parse(rec_name, varargin{:});
gqpost = p.Results.gqpost;
gqconf = p.Results.gqconf;
window_size_sec = p.Results.window_size_sec;

%% === Run gqrs
ecg_col = get_signal_channel(rec_name);
[gqrs_detections, gqrs_outliers] = gqrs(rec_name, 'ecg_col', ecg_col, 'gqpost', gqpost, 'gqconf', gqconf);

%% === Read Signal
[tm, sig, ~] = rdsamp(rec_name, ecg_col);

%% === Try Set window size intelligently from config
% Check whether the window size was specfied explicitly by caller. If so,
% use that. Otherwise, if gqconf was specified, look for the QS parameter
% in the file and set window size based on it.

window_size_was_specified = ~any(cellfun(@(s) strcmp(s,'window_size_sec'), p.UsingDefaults));
gqconf_was_specified      = ~any(cellfun(@(s) strcmp(s,'gqconf'),          p.UsingDefaults));

if gqconf_was_specified && ~window_size_was_specified
    % Parse QS from config file
    qs = read_qs_from_conf(gqconf);

    % If QS was defined in the config file, use 80% of it as window size, otherwise leave the
    % default value for window size.
    if ~isnan(qs)
        window_size_sec = 0.8 * qs;
    end
end

%% === Augment gqrs detections
[ qrs, outliers ] = rqrs_augment(gqrs_detections, gqrs_outliers, tm, sig, 'window_size_sec', window_size_sec);

% Plot if no output arguments
if (nargout == 0)
    figure;
    plot(tm, sig); hold on; grid on;
    plot(tm(qrs), sig(qrs,1), 'rx');
    xlabel('time [s]'); ylabel ('ECG [mV]');

    if (~isempty(outliers))
        plot(tm(outliers), sig(outliers,1), 'ko');
        legend('signal', 'qrs detections', 'suspected outliers');
    else
        legend('signal', 'qrs detections');
    end
end

%% === Helper functions

% Parses the gqconf file to extract the 'QS' parameter
function qs = read_qs_from_conf(gqconf)
    qs = NaN;
    config_text = fileread(gqconf);
    tokens = regexpi(config_text, '(?:[\n]|^)\s*QS\s+(\d*\.?\d+)', 'tokens');
    if ~isempty(tokens)
        qs = str2double(tokens{end});
    end
end

end
