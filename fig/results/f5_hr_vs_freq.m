close all;

%% Analyze data
folder = 'db/billman';
rec_types = {'*pre-*-bsl', '*pre-*-dbk','*post-*-bsl', '*post-*-dbk'};
rec_names = {'Pre BSL', 'Pre DBK','Post BSL', 'Post DBK'};
power_methods = {'lomb','ar'};

hrv_tables = rhrv_batch(folder,...
    'rec_types', rec_types,...
    'rec_names', rec_names,...
    'rhrv_params', {'canine', 'hrv_freq.power_methods', power_methods}...
);

%% Plot correlations

for rec_type_idx = 1:length(hrv_tables)
    curr_table = hrv_tables{rec_type_idx};

    figure('Name', [rec_names{rec_type_idx} ': Freq to HR fitting']);
    hold(gca, 'on'); grid(gca, 'on');
    xlabel(gca, 'HR [BPM]');
    ylabel(gca, 'Freq. [Hz]');
    ylim(gca, [0,0.7]);

    colors = {'b','r'};
    for ii = 1:length(power_methods)

        hr = 60./curr_table.AVNN;

        lf = curr_table{:,['LF_PEAK_' upper(power_methods{ii})]};
        hf = curr_table{:,['HF_PEAK_' upper(power_methods{ii})]};

        [~, sort_order] = sort(hr);
        hr = hr(sort_order);
        lf = lf(sort_order);
        hf = hf(sort_order);

        lf_fit = polyfit(hr(~isnan(lf)), lf(~isnan(lf)), 1);
        hf_fit = polyfit(hr(~isnan(hf)), hf(~isnan(hf)), 1);

        h_lf_pts = plot(hr, lf, ['x' colors{ii}], 'MarkerSize', 8, 'DisplayName', sprintf('LF (%s)', power_methods{ii}));
        h_hf_pts = plot(hr, hf, ['o' colors{ii}], 'MarkerSize', 8, 'DisplayName', sprintf('HF (%s)', power_methods{ii}));
        h_lf_fit = plot(hr, polyval(lf_fit, hr), ['-' colors{ii}], 'LineWidth', 2, 'DisplayName', sprintf('LF fit (%s)', power_methods{ii}));
        h_hf_fit = plot(hr, polyval(hf_fit, hr), ['-' colors{ii}], 'LineWidth', 2, 'DisplayName', sprintf('HF fit (%s)', power_methods{ii}));

        legend(gca,'show');
    end
end
