function [table_data, handles] = swa_sleep_statistics(EEG, flag_plot, language, flag_mode)
% calculate basic statistics from sleep scoring

% 2nd column is
% 3rd column is

% check inputs
if nargin < 2
    flag_plot = false;
end
if nargin < 3
    language = 'german';
end
if nargin < 4
    flag_mode = 0; % default to classic sleep scoring mode
end


% define empty handles in case flag_plot is 0
handles = [];

% initialise the table
table_data = cell(12, 4);

% define the categories
switch lower(language)
    case {'german', 'deutsch'}
        table_data{1, 1} = 'Total Aufnehmungszeit (min)';
        table_data{2, 1} = 'Total Schlaf (min)';
        table_data{3, 1} = 'Total Wach (min)';
        table_data{4, 1} = 'Total Stadium 1 (min)';
        table_data{5, 1} = 'Total Stadium 2 (min)';
        table_data{6, 1} = 'Total Stadium 3 (min)';
        table_data{7, 1} = 'Total Stadium REM (min)';
        table_data{8, 1} = 'Latenz zu S1 (min)';
        table_data{9, 1} = 'Latenz zu S2 (min)';
        table_data{10, 1} = 'Latenz zu S3 (min)';
        table_data{11, 1} = 'Latenz zu REM (min)';
        table_data{12, 1} = 'Stadienwechsel';
        
    case 'english'
        table_data{1, 1} = 'total recording time';
        table_data{2, 1} = 'total sleep';
        table_data{3, 1} = 'total wake';
        table_data{4, 1} = 'total N1';
        table_data{5, 1} = 'total N2';
        table_data{6, 1} = 'total N3';
        table_data{7, 1} = 'total REM';
        table_data{8, 1} = 'latency N1';
        table_data{9, 1} = 'latency N2';
        table_data{10, 1} = 'latency N3';
        table_data{11, 1} = 'latency REM';
        table_data{12, 1} = 'no. transitions';
end

% calculate the borders of sleep
wake_start = find(diff([0, EEG.swa_scoring.stages == 0 | EEG.swa_scoring.stages == 6]) == 1);
wake_end = find(diff([0, EEG.swa_scoring.stages == 0 | EEG.swa_scoring.stages == 6]) == -1);
lights_off = wake_start(1);
sleep_onset = wake_end(1) - lights_off;

% check for last stage sleep
% calculate how much wake time there is after sleep finishes
if EEG.swa_scoring.stages(end) == 0
    wake_time_after_sleep = length(EEG.swa_scoring.stages) - wake_start(end);
else
    wake_time_after_sleep = 0;
end

% sleep time adjustment
adjustment_prepost_sleep = (sleep_onset + wake_time_after_sleep) / EEG.srate / 60;

% aretefact time during sleep
if flag_mode == 1
    artefact_time = sum(EEG.swa_scoring.arousals (lights_off : wake_start(end)));
else
    artefact_time = 0;
end

% ============================================================================ %
% adjusted for setup time before lights off
% adjusted for artefact time (ignore this time]

% calculate the total time and percentages
table_data{1, 2} = [length(EEG.swa_scoring.stages) - lights_off - artefact_time] / EEG.srate / 60;

% N1 latency
N1_starts = find(diff([1, EEG.swa_scoring.stages == 1]) == 1) - 1;
table_data{8, 2} = [N1_starts(1) - lights_off] / EEG.srate / 60;

% total sleep
table_data{2, 2} = [sum(EEG.swa_scoring.stages > 0) - artefact_time] / EEG.srate / 60;
table_data{2, 3} = table_data{2, 2} / table_data{1, 2} * 100;
table_data{2, 4} = table_data{2, 2} / (table_data{1, 2} - adjustment_prepost_sleep - table_data{8, 2}) * 100;

% total wake
table_data{3, 2} = sum(EEG.swa_scoring.stages == 0) / EEG.srate / 60;
table_data{3, 3} = table_data{3, 2} / table_data{1, 2} * 100;
table_data{3, 4} = (table_data{3, 2} - adjustment_prepost_sleep) / (table_data{1, 2} - adjustment_prepost_sleep - - table_data{8, 2}) * 100;

% total N1
table_data{4, 2} = sum(EEG.swa_scoring.stages == 1) / EEG.srate / 60;
table_data{4, 3} = table_data{4, 2}/table_data{1, 2} * 100;
table_data{4, 4} = table_data{4, 2}/table_data{2, 2} * 100;

% total N2
table_data{5, 2} = sum(EEG.swa_scoring.stages == 2) / EEG.srate / 60;
table_data{5, 3} = table_data{5, 2}/table_data{1, 2} * 100;
table_data{5, 4} = table_data{5, 2}/table_data{2, 2} * 100;

% total N3
table_data{6, 2} = sum(EEG.swa_scoring.stages == 3) / EEG.srate / 60;
table_data{6, 3} = table_data{6, 2}/table_data{1, 2} * 100;
table_data{6, 4} = table_data{6, 2}/table_data{2, 2} * 100;

% total REM
table_data{7, 2} = sum(EEG.swa_scoring.stages == 5) / EEG.srate / 60;
table_data{7, 3} = table_data{7, 2}/table_data{1, 2} * 100;
table_data{7, 4} = table_data{7, 2}/table_data{2, 2} * 100;


% -- calculate latencies -- %
% N2 latency
N2_starts = find(diff([1, EEG.swa_scoring.stages == 2]) == 1) - 1;
if ~isempty(N2_starts)
    table_data{9, 2} = [N2_starts(1) - lights_off] / EEG.srate / 60;
    table_data{9, 3} = table_data{9, 2} - table_data{8, 2};
end

% N3 latency
N3_starts = find(diff([1, EEG.swa_scoring.stages == 3]) == 1) - 1;
if ~isempty(N3_starts)
    table_data{10, 2} = [N3_starts(1)  - lights_off] / EEG.srate / 60;
    table_data{10, 3} = table_data{10, 2} - table_data{8, 2};
    table_data{10, 4} = table_data{10, 2} - table_data{9, 2};
end

% REM latency
REM_starts = find(diff([1, EEG.swa_scoring.stages == 5]) == 1) - 1;
if ~isempty(REM_starts)
    table_data{11, 2} = [REM_starts(1) - lights_off] / EEG.srate / 60;
    table_data{11, 3} = table_data{11, 2} - table_data{8, 2};
    table_data{11, 4} = table_data{11, 2} - table_data{9, 2};
end

% other stats
% number of stage transitions
table_data{12, 2} = length(find(diff(EEG.swa_scoring.stages))) ...
    - length(find(diff([1, EEG.swa_scoring.stages == 4]) == 1));

% plot the table in separate figure
if flag_plot
    handles = plot_table(table_data);
end

function handles = plot_table(table_data)

handles.fig = figure(...
    'Name',         'Sleep Scoring',...
    'NumberTitle',  'off',...
    'Color',        [0.1, 0.1, 0.1],...
    'MenuBar',      'none',...
    'Units',        'normalized',...
    'Outerposition',[0.25 0.10 0.5 0.8]);

% draw axes
handles.axes_pie = axes(...
    'parent',       handles.fig             ,...
    'position',     [0.3 0.1, 0.4, 0.4],...
    'nextPlot',     'add'                   ,...
    'color',        'none' ,...
    'xtick',        []                      ,...
    'ytick',        []                      );

% montage table
handles.table = uitable(...
    'parent',       handles.fig             ,...
    'units',        'normalized'            ,...
    'position',     [0.05, 0.6, 0.9, 0.3]   ,...
    'backgroundcolor', [0.1, 0.1, 0.1; 0.2, 0.2, 0.2],...
    'foregroundcolor', [0.9, 0.9, 0.9]      ,...
    'enable', 'inactive', ...
    'rowName', [], ...
    'columnName',   {'statistic', 'time', '% night', '% sleep'});

% get the underlying java properties
pause(1);
jscroll = findjobj(handles.table);
jscroll.setVerticalScrollBarPolicy(jscroll.java.VERTICAL_SCROLLBAR_ALWAYS);

% make the table sortable
% get the java table from the jscroll
jtable = jscroll.getViewport.getView;
jtable.setSortable(true);
jtable.setMultiColumnSortable(true);

% auto-adjust the column width
jtable.setAutoResizeMode(jtable.AUTO_RESIZE_ALL_COLUMNS);
jtable.setAutoResizeMode(jtable.AUTO_CELL_MERGE_ROWS);

% put the data into the table
set(handles.table, 'data', table_data);

% make a pie chart
pie_data = cell2mat(table_data(3:7, 4));
pie_labels = {'wake', 'N1', 'N2', 'N3', 'REM'};
handles.pie = pie(handles.axes_pie, pie_data, pie_labels);

% set color
[handles.pie(2:2:10).Color] = deal([.7 .7 .7]);