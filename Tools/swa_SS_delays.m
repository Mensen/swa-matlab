function [delay, duration, time_series] = swa_SS_delays(Data, Info, SS, flag_plot)
% plot the delays in power spectra between frontal and parietal

if nargin < 4
    flag_plot = true;
end

% define trial parameters
window_length = floor(0.5 * Info.Recording.sRate);

% look for spindles that are out of range
SS([SS.Ref_Start] - window_length < 1) = [];
SS([SS.Ref_Start] + window_length > Info.Recording.dataDim(2)) = [];

% pre-allocate
canonical_segment = nan(2, window_length * 2 + 1, length(SS));

% loop for each slow wave
for n = 1 : length(SS)
       
    % define the time range around the start
    range = SS(n).Ref_Start - window_length ...
        : SS(n).Ref_Start + window_length;
    
    % extract the power curve from each spindle for frontal and parietal ref
    canonical_segment(:, :, n) = Data.CWT([1,3], range);
    
end

% normalise the amplitude
time_series = mean(canonical_segment, 3);
time_series(1, :) = [time_series(1, :) - min(time_series(1, :))] / ...
    max([time_series(1, :) - min(time_series(1, :))]);
time_series(2, :) = [time_series(2, :) - min(time_series(2, :))] / ...
    max([time_series(2, :) - min(time_series(2, :))]);

% calculate the delay (time difference to 50% max)
half_s1 = find(time_series(1, :) > 0.5);
half_s2 = find(time_series(2, :) > 0.5);
delay = [half_s2(1) - half_s1(1)] / Info.Recording.sRate;
duration = [[half_s2(end) - half_s2(1)] - [half_s1(end) - half_s1(1)]] / Info.Recording.sRate;

if flag_plot
    % plot a spindle power
    time_range = linspace(-0.5, 0.5, length(range));
    handles.fig = figure('color', 'w');
    handles.ax = axes('parent', handles.fig, ...
        'ColorOrder', parula(3));
    % normalise the means for each wave separately
    handles.line = plot(time_range, time_series, ...
        'linewidth', 3);
end

% canonical_segment(1, :, :) = canonical_segment(1, :, :) * 1.8;
% handles.line = plot(time_range, mean(canonical_segment, 3))