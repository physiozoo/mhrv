function [ GMModel, peaks ] = freqband_detect( pxx_dataset, varargin )
%FREQBAND_DETECT Detect frequency bands from multiple specrums of RR intervals
%   This function uses an automated clustering algorithm to attempt to detect bands with
%   high frequency power from a dataset containing multiple power spectrums obtained from RR intervals.

% Define input
p = inputParser;
p.addRequired('pxx_dataset', @iscell);
p.addParameter('n_bands', 3, @(x)isscalar(x)&&isnumeric(x));
p.addParameter('k_range', [], @(x)isnumeric(x));
p.addParameter('normalize', true);
p.addParameter('max_peaks', 10, @(x)isempty(x)||(isscalar(x)&&isnumeric(x)));
p.addParameter('peak_min_height', 0.05, @(x) x >= 0 && x <= 1);
p.addParameter('replicates', 5, @(x)isscalar(x)&&floor(x)==x);
p.addParameter('model_dim', 1, @(x) x==1 || x==2);
p.addParameter('output_filename', [], @ischar);

% Get input
p.parse(pxx_dataset, varargin{:});
n_bands = p.Results.n_bands;
k_range = p.Results.k_range;
normalize = p.Results.normalize;
max_peaks = p.Results.max_peaks;
peak_min_height = p.Results.peak_min_height;
replicates = p.Results.replicates;
model_dim = p.Results.model_dim;
output_filename = p.Results.output_filename;

%% Detect peaks

% Disable warnings about min peak height
warnstate = warning;
warning('off','signal:findpeaks:largeMinPeakHeight');

peaks = cell(length(pxx_dataset), 1);
for ii = 1:length(pxx_dataset)
    % Get current spectrum, and reshape it into Nx2
    spect = reshape(pxx_dataset{ii}, [], 2);
    pxx = spect(:,1);
    f_axis = spect(:,2);

    % Normalize spectrum
    if normalize
        pxx = pxx ./ max(pxx);
        abs_peak_min_height = peak_min_height;
    else
        abs_peak_min_height = peak_min_height * max(pxx);
    end

    % Find peaks if requested
    if ~isempty(max_peaks)
        [curr_peaks_pxx, curr_peaks, ~, ~] = findpeaks(pxx, f_axis,...
            'SortStr', 'descend', 'NPeaks', max_peaks, 'MinPeakHeight', abs_peak_min_height);
    else
        curr_peaks_pxx = pxx;
        curr_peaks = f_axis;
    end

    peaks{ii} = [curr_peaks, curr_peaks_pxx];
end
warning(warnstate);

% Convert to a long Nx1 vector of all peaks
peaks = cell2mat(peaks);

%% Fit Model

% Take the columns of peaks according to the dimension of the model
cluster_dataset = peaks(:,1:model_dim);

% Calculate AIC/BIC metrics over a range of k values (if requested)
aic = zeros(size(k_range));
bic = zeros(size(k_range));
if ~isempty(k_range)
    % Disable warnings about convergence while testing different k's
    warnstate = warning;
    warning('off','stats:gmdistribution:FailedToConvergeReps');

    for kk = k_range
        GMModel = fitgmdist(cluster_dataset, kk, 'Start', 'plus', 'Replicates', replicates);
        aic(kk) = GMModel.AIC;
        bic(kk) = GMModel.BIC;
    end
    figure;
    plot(k_range, aic, k_range, bic);
    set(gca,'XTick',k_range);
    grid on; legend('AIC', 'BIC');

    warning(warnstate);
end

% Fit the final model with the requested number of bands
GMModel = fitgmdist(cluster_dataset, n_bands, 'Start', 'plus', 'Replicates', replicates);
labels = cluster(GMModel, cluster_dataset);

% Sort cluster parameters by frequency
[~, sort_idx] = sort(GMModel.mu(:,1));
C_mu = GMModel.mu(sort_idx,:);
C_sigma2 = GMModel.Sigma(:,:,sort_idx);
C_alpha = GMModel.ComponentProportion(sort_idx);

sorted_labels = zeros(size(labels));
for cidx = 1:n_bands
    sorted_labels(labels == sort_idx(cidx)) = cidx;
end
labels = sorted_labels;
clear sorted_labels;

%% Visualize data
colors = lines(n_bands);
scatter_size = 100;
scatter_marker = '.';

fig = figure; ax = gca;
grid(ax, 'on'); hold(ax, 'on');

% Plot data of each cluster
freq_band = [min(peaks(:,1)), max(peaks(:,1))];
legend_handles = cell(1, n_bands);
legend_entries = cell(1, n_bands);
xpdf = freq_band(1):0.005:freq_band(2);

for jj = 1:n_bands
    % Current cluster parameters
    cidx = labels == jj;
    csize = nnz(cidx);
    cmu = C_mu(jj,1);
    calpha = C_alpha(jj);

    % Find eigenvactors/values for the covariance matrix.
    % The eigenvector with the maximal eigenvalue is the main component of the covariance
    % matrix. We'll find the variance along that component, and then take only the first element
    % because we want to project this variance onto the f-axis.
    [V,D] = eig(C_sigma2(:,:,jj));
    [~,imax] = max(sum(D,1));
    csigma2_principal_component = C_sigma2(:,:,jj) * V(:,imax);
    csigma = sqrt(abs(csigma2_principal_component(1)));

    % Plot PDF of current cluster
    ypdf = normpdf(xpdf,cmu,csigma);
    ypdf = ypdf .* calpha;
    plot(ax, xpdf,ypdf, 'Color', colors(jj,:), 'LineWidth', 3, 'LineStyle', '-', 'Marker', 'none', 'MarkerEdgeColor','black');

    % Normalize the height of the points in the cluster by the estimated PDF (just so they're more
    % visible in the plot)
    peaks_f = peaks(cidx,1);
    peaks_pxx = peaks(cidx,2) ./ max(peaks(cidx,2)) .* max(ypdf);

    % Plot the points in the current cluster
    legend_handles{jj} = scatter(ax, peaks_f, peaks_pxx, scatter_size, colors(jj,:), scatter_marker);
    legend_entries{jj} = sprintf('%.3fHz, n=%d, std=%.3f', cmu, csize, csigma);
end
legend(ax, [legend_handles{:}], legend_entries, 'location', 'northeast');
xlabel(ax, 'Frequency (Hz)'); ylabel(ax, 'PSD Peak Distribution');

%% Print

if ~isempty(output_filename)
    fig_print(fig, output_filename, 'width', 20,'height', 15);
end

end

