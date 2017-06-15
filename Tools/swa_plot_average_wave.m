function g = swa_plot_average_wave(Data, Info, SW)
% plot the average slow wave

number_of_sw = length(SW);

% define ERP range
time_range = linspace(-0.5, 0.5, Info.Recording.sRate);
sample_range = floor(time_range * Info.Recording.sRate);
time_range = time_range * 1000; % turn time range into ms

all_slow_wave = cell(size(Data.SWRef, 1), 1);
wave_type = nan( [number_of_sw - 2] * 3, 1);
for nc = 1 : size(Data.SWRef, 1)
    
    all_slow_wave{nc} = zeros(number_of_sw - 2, size(sample_range, 2));
    
    for n = 2 : number_of_sw - 1
        
        current_range = sample_range + SW(n).Ref_PeakInd;
        
        all_slow_wave{nc}(n, :) = Data.SWRef(nc, current_range);
        
    end
    
    % eliminate first slow wave
    all_slow_wave{nc}(1, :) = [];
    
    wave_type ([number_of_sw - 2] * [nc - 1] + 1 : [number_of_sw - 2] * nc) = nc;
    
end

% convert to matrix
stack_waves = cell2mat(all_slow_wave);

% use gramm to plot
g = gramm('y', stack_waves(:, :), ...
    'x', time_range, ...
    'color', wave_type);
g.stat_summary('type', 'sem');
g.draw;

% g.facet_axes_handles.YLim = ([-1250, 1000]);
saveas(gcf, 'slow_wave_average.svg')