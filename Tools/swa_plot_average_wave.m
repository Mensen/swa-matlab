function [g, all_slow_wave] = swa_plot_average_wave(data_in, Info, SW, time_window, flag_plot)
% plot the average slow wave

% check inputs
if nargin < 5
    flag_plot = true;
end

if nargin < 4
    time_window = 0.5;
end

number_of_sw = length(SW);
g = [];

% define ERP range
time_range = linspace(-time_window, time_window, Info.Recording.sRate);
sample_range = floor(time_range * Info.Recording.sRate);
time_range = time_range * 1000; % turn time range into ms

% pre-allocate trial data
all_slow_wave = nan(number_of_sw, length(sample_range));

% get each slow wave
for n = 1 : number_of_sw
    
    current_range = sample_range + SW(n).Ref_PeakInd;
    current_range(current_range < 1) = 1;
    
    all_slow_wave(n, :) = data_in(1, current_range);
    
end

% use gramm to plot
if flag_plot
    g = gramm('y', all_slow_wave(:, :), ...
        'x', time_range);
    g.stat_summary('type', 'std');
    g.draw;
end