function handles = swa_plot_example(Data, Info, SW, selected_wave, buffer_time)
% plot an example slow wave with highlights wave portion and raw data background

% check inputs
if nargin < 4
    % select specific slow wave
    selected_wave = floor(length(SW/2));
end

if nargin < 5
    % define time buffer before and after selected wave
    buffer_time = 15;
end

% display buffer
buffer = floor(Info.Recording.sRate * buffer_time);
range = SW(selected_wave).Ref_PeakInd - buffer : ...
    SW(selected_wave).Ref_PeakInd + buffer;
range(range < 1) = 1;
time_range = range / Info.Recording.sRate;

% open new figure
handles.fig = figure('color', 'w', ...
    'units', 'normalized', ...
    'position', [0, 0.5, 1, 0.48]);
handles.ax = axes('nextplot', 'add', ...
    'units', 'normalized', ...
    'position', [0.05, 0.1, 0.9, 0.8], ...
    'xlim', [time_range(1), time_range(end)]);

% turn time in hours/minutes
tick_samples = get(handles.ax, 'XTick');
tick_times = seconds(tick_samples);
tick_labels = cellstr(char(tick_times, 'hh:mm:ss'));
set(handles.ax, 'XTickLabels', tick_labels);

% plot the outline of the raw data
maximum_line = prctile(Data.Raw(:, range), 95);
minimum_line = prctile(Data.Raw(:, range), 5);

% butterfly plot as a single patch object
handles.patch = patch(...
    [time_range, fliplr(time_range)], ...
    [maximum_line, fliplr(minimum_line)],...
    [0.9, 0.9, 0.9],...
    'edgeColor', [0.5, 0.5, 0.5]);

% handles.raw = plot(time_range, Data.Raw(:, range), ...
%     'color', [0.8, 0.8, 0.8], ...
%     'linewidth', 1);

% calculate data which is detected as a slow wave
highlighted_data = nan(1, size(Data.SWRef(1, :), 2));
for n = 1 : length(SW)
    sample_range = SW(n).Ref_DownInd : SW(n).Ref_UpInd;
    highlighted_data(1, sample_range) = Data.SWRef(SW(n).Ref_Region(1), sample_range);
end

% plot the canonical series
handles.canon = plot(time_range, Data.SWRef(:, range), ...
    'color', [0.5, 0.5, 0.5], ...
    'linewidth', 2);

% highlight slow wave portion
highlight_data = highlighted_data(1, range);
handles.highlight = plot(time_range, highlight_data, ...
    'color', [0, 0, 1], ...
    'linewidth', 3);

% plot threshold line
handles.zero = line([time_range(1), time_range(end)], [0, 0], ...
    'color', [0.5, 0.5, 0.5], ...
    'linestyle', ':');
handles.threshold = line([time_range(1), time_range(end)], ...
    [-Info.Parameters.Ref_AmplitudeAbsolute, -Info.Parameters.Ref_AmplitudeAbsolute], ...
    'color', [0.3, 0.3, 0.3], ...
    'linestyle', ':');