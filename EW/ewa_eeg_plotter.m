function ewa_eeg_plotter()

%TODO: Main page 
        %Scale - green lines across one of the channels
        %Video scroll with space bar - reasonable speed - pause/play?
        %Auto adjust time scale on bottom for whole night
        %left side epoch length/scale boxes
        %top center box stating what is in the epoch (much like sleep scoring)
        %highlight spikes, makes tick below
        %Scoring axis
            %click where you wish to go
            %ticks or mapping (like sleep scoring) only marked seizure, spike, artifact
        %Display button? way to visualize event related EEG data while scoring?
        %Options button? channel/window length and print button

%TODO: Montage
        %Green line in front of headset
        %headset electrodes smaller due to poor resolution on my computer
        %functional delete/apply buttons, as well as a revert button
        %name of montage top center of headset
        %Tool bar has a drop down menu: for example; new, 10-20, etc.

% make a window
% ~~~~~~~~~~~~~
handles.fig = figure(...
    'name',         'ewa EEG Plotter',...
    'numberTitle',  'off',...
    'color',        [0.1, 0.1, 0.1],...
    'menuBar',      'none',...
    'units',        'normalized',...
    'outerPosition',[0 0.04 .5 0.96]);

% make the axes
% ~~~~~~~~~~~~~
% main axes
handles.main_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0.05 0.2, 0.9, 0.75]   ,...
    'nextPlot',     'add'                   ,...
    'color',        [0.2, 0.2, 0.2]         ,...
    'xcolor',       [0.9, 0.9, 0.9]         ,...
    'ycolor',       [0.9, 0.9, 0.9]         ,...  
    'ytick',        []                      ,...
    'fontName',     'Century Gothic'        ,...
    'fontSize',     8                       );

% navigation/spike axes
handles.spike_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0.05 0.075, 0.9, 0.05] ,...
    'nextPlot',     'add'                   ,...
    'color',        [0.2, 0.2, 0.2]         ,...
    'xcolor',       [0.9, 0.9, 0.9]         ,...
    'ycolor',       [0.9, 0.9, 0.9]         ,...   
    'ytick',        []                      ,...   
    'fontName',     'Century Gothic'        ,...
    'fontSize',     8                       );

% invisible name axis
handles.name_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0 0.2, 0.1, 0.75]   ,...
    'visible',      'off');

% create the menu bar
% ~~~~~~~~~~~~~~~~~~~
handles.menu.file       = uimenu(handles.fig, 'label', 'file');
handles.menu.load       = uimenu(handles.menu.file,...
    'Label', 'load eeg',...
    'Accelerator', 'l');
handles.menu.save       = uimenu(handles.menu.file,...
    'Label', 'save eeg',...
    'Accelerator', 's');

handles.menu.montage    = uimenu(handles.fig, 'label', 'montage', 'enable', 'off');

handles.menu.options    = uimenu(handles.fig, 'label', 'options');
handles.menu.disp_chans = uimenu(handles.menu.options,...
    'label', 'display channels',...
    'accelerator', 'd');



% scale indicator
% ~~~~~~~~~~~~~~~
handles.txt_scale = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'text',...
    'String',   '100',...
    'Visible',  'off',...
    'Value',    100);


% hidden epoch tracker
% ````````````````````
handles.cPoint = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'text',...
    'Visible',  'off',...
    'Value',    1);

% set the callbacks
% ~~~~~~~~~~~~~~~~~
set(handles.menu.load, 'callback', {@fcn_load_eeg});
set(handles.menu.montage, 'callback', {@fcn_montage_setup});

set(handles.menu.disp_chans, 'callback', {@fcn_options, 'disp_chans'});

set(handles.fig,...
    'KeyPressFcn', {@cb_key_pressed,});

set(handles.spike_ax, 'buttondownfcn', {@fcn_time_select});

guidata(handles.fig, handles)


function fcn_load_eeg(object, ~)
% get the handles structure
handles = guidata(object);

% load dialog box with file type
[dataFile, dataPath] = uigetfile('*.set', 'Please Select Sleep Data');

% just return if no datafile was actually selected
if dataFile == 0
    fprintf(1, 'Warning: No file selected \n');
    return;
end

% load the files
% ``````````````
% load the struct to the workspace
load([dataPath, dataFile], '-mat');
if ~exist('EEG', 'var')
    fprintf('Warning: No EEG structure found in file\n');
    return;
end

% memory map the actual data...
tmp = memmapfile(EEG.data,...
                'Format', {'single', [EEG.nbchan EEG.pnts EEG.trials], 'eegData'});
eegData = tmp.Data.eegData;

% set the name
set(handles.fig, 'name', ['ewa: ', dataFile]);

% check for the channel locations
if isempty(EEG.chanlocs)
    if isempty(EEG.urchanlocs)
        fprintf(1, 'Warning: No channel locations found in the EEG structure \n');
    else
        fprintf(1, 'Information: Taking the EEG.urchanlocs as the channel locations \n');
        EEG.chanlocs = EEG.urchanlocs;
    end
end

% check for previous
if ~isfield(EEG, 'ewa_montage')
    % assign defaults
    EEG.ewa_montage.display_channels    = 12;
    EEG.ewa_montage.epoch_length        = 30;
    EEG.ewa_montage.label_channels      = cell(EEG.ewa_montage.display_channels, 1);
    EEG.ewa_montage.label_channels(:)   = deal({'undefined'});
    EEG.ewa_montage.channels(:,1)       = [1:EEG.ewa_montage.display_channels]';
    EEG.ewa_montage.channels(:,2)       = size(eegData, 1);
    EEG.ewa_montage.filter_options      = [0.5; 30]';
end
    
% update the handles structure
guidata(handles.fig, handles)
% use setappdata for data storage to avoid passing it around in handles when not necessary
setappdata(handles.fig, 'EEG', EEG);
setappdata(handles.fig, 'eegData', eegData);

% turn on the montage option
set(handles.menu.montage, 'enable', 'on');

% plot the initial data
plot_initial_data(handles.fig)


function plot_initial_data(object)
% get the handles structure
handles = guidata(object);

% get the data
EEG = getappdata(handles.fig, 'EEG');
eegData = getappdata(handles.fig, 'eegData');

% select the plotting data
range       = 1:EEG.ewa_montage.epoch_length*EEG.srate;
channels    = 1:EEG.ewa_montage.display_channels;
data        = eegData(EEG.ewa_montage.channels(channels,1), range) - eegData(EEG.ewa_montage.channels(channels,2), range);

% filter the data
% ~~~~~~~~~~~~~~~
[EEG.filter.b, EEG.filter.a] = ...
        butter(2,[EEG.ewa_montage.filter_options(1)/(EEG.srate/2),...
                  EEG.ewa_montage.filter_options(2)/(EEG.srate/2)]);
data = single(filtfilt(EEG.filter.b, EEG.filter.a, double(data'))'); %transpose data twice

% plot the data
% ~~~~~~~~~~~~~
% define accurate spacing
scale = get(handles.txt_scale, 'value')*-1;
toAdd = [1:EEG.ewa_montage.display_channels]'*scale;
toAdd = repmat(toAdd, [1, length(range)]);

% space out the data for the single plot
data = data+toAdd;

set([handles.main_ax, handles.name_ax], 'yLim', [scale 0]*(EEG.ewa_montage.display_channels+1))

% in the case of replotting delete the old handles
if isfield(handles, 'plot_eeg')
    delete(handles.plot_eeg);
    delete(handles.labels);
    delete(handles.indicator);
end

% calculate the time in seconds
time = range/EEG.srate;
set(handles.main_ax,  'xlim', [time(1), time(end)]);
handles.plot_eeg = line(time, data,...
                        'color', [0.9, 0.9, 0.9],...
                        'parent', handles.main_ax);
                  
% plot the labels in their own boxes
handles.labels = zeros(length(EEG.ewa_montage.label_channels(channels)), 1);
for chn = 1:length(EEG.ewa_montage.label_channels(channels))
    handles.labels(chn) = ...
        text(0.5, toAdd(chn,1)+scale/5, EEG.ewa_montage.label_channels{chn},...
        'parent', handles.name_ax,...
        'fontsize',   12,...
        'fontweight', 'bold',...
        'color',      [0.8, 0.8, 0.8],...
        'backgroundcolor', [0.1 0.1 0.1],...
        'horizontalAlignment', 'center',...
        'buttondownfcn', {@fcn_hide_channel});
end
                    
% change the x limits of the indicator plot
set(handles.spike_ax,   'xlim', [0, size(eegData, 2)],...
                        'ylim', [0, 1]);
                    
% add indicator line to lower plot
handles.indicator = line([range(1), range(1)], [0, 1],...
                        'color', [0.9, 0.9, 0.9],...
                        'linewidth', 3,...
                        'parent', handles.spike_ax,...
                        'hittest', 'off');
                    
% set the new parameters
guidata(handles.fig, handles);
setappdata(handles.fig, 'EEG', EEG);
             

function fcn_update_axes(object, ~)
% get the handles structure
handles = guidata(object);

% get the data
EEG = getappdata(handles.fig, 'EEG');
eegData = getappdata(handles.fig, 'eegData');
        
% select the plotting data
current_point = get(handles.cPoint, 'value');
range       = current_point:current_point+EEG.ewa_montage.epoch_length*EEG.srate-1;
channels    = 1:EEG.ewa_montage.display_channels;
data        = eegData(EEG.ewa_montage.channels(channels, 1), range) - eegData(EEG.ewa_montage.channels(channels, 2), range);

data = single(filtfilt(EEG.filter.b, EEG.filter.a, double(data'))'); %transpose data twice

% plot the data
% ~~~~~~~~~~~~~
% define accurate spacing
scale = get(handles.txt_scale, 'value')*-1;
toAdd = [1:EEG.ewa_montage.display_channels]'*scale;
toAdd = repmat(toAdd, [1, length(range)]);

% space out the data for the single plot
data = data+toAdd;

% calculate the time in seconds corresponding to the range in samples
time = range/EEG.srate;

% set the xlimits explicitely just in case matlab decides to give space
set(handles.main_ax,  'xlim', [time(1), time(end)]);

% set the x-axis to the time in seconds
set(handles.plot_eeg, 'xdata', time);

% reset the ydata of each line to represent the new data calculated
for n = 1:EEG.ewa_montage.display_channels
    set(handles.plot_eeg(n), 'ydata', data(n,:));
end 


function fcn_change_time(object, ~)
% get the handles from the guidata
handles = guidata(object);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

current_point = get(handles.cPoint, 'value');
if current_point < 1
    fprintf(1, 'This is the first sample \n');
    set(handles.cPoint, 'value', 1);
elseif current_point > EEG.pnts
    fprintf(1, 'No more data \n');
    set(handles.cPoint, 'value', EEG.pnts-(EEG.ewa_montage.epoch_length*EEG.srate));
end
current_point = get(handles.cPoint, 'value');

% update the hypnogram indicator line
set(handles.indicator, 'Xdata', [current_point, current_point]);

% update the GUI handles
guidata(handles.fig, handles)
setappdata(handles.fig, 'EEG', EEG);

% update all the axes
fcn_update_axes(handles.fig);


function fcn_hide_channel(object, ~);
% get the handles from the guidata
handles = guidata(object);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

ch = find(handles.labels == object);

state = get(handles.plot_eeg(ch), 'visible');

switch state
    case 'on'
        set(handles.plot_eeg(ch), 'visible', 'off');
    case 'off'
        set(handles.plot_eeg(ch), 'visible', 'on');
end


function fcn_time_select(object, ~)
handles = guidata(object);

% get position of click
clicked_position = get(handles.spike_ax, 'currentPoint');

set(handles.cPoint, 'Value', floor(clicked_position(1,1)));
fcn_change_time(object, []);


function cb_key_pressed(object, event)
% get the relevant data
handles = guidata(object);
EEG = getappdata(handles.fig, 'EEG');

% movement keys
if isempty(event.Modifier)
    switch event.Key
        case 'leftarrow'
            % move to the previous epoch
            set(handles.cPoint, 'Value',...
                get(handles.cPoint, 'Value') - EEG.ewa_montage.epoch_length*EEG.srate);
            fcn_change_time(object, [])
            
        case 'rightarrow'
            % move to the next epoch
            set(handles.cPoint, 'Value',...
                get(handles.cPoint, 'Value') + EEG.ewa_montage.epoch_length*EEG.srate);
            fcn_change_time(object, [])
            
        case 'uparrow'
            scale = get(handles.txt_scale, 'value');
            if scale <= 20
                value = scale / 2;
                set(handles.txt_scale, 'value', value);
            else
                value = scale - 20;
                set(handles.txt_scale, 'value', value);
            end
            
            set(handles.txt_scale, 'string', get(handles.txt_scale, 'value'));
            set(handles.main_ax, 'yLim', [get(handles.txt_scale, 'value')*-1, 0]*(EEG.ewa_montage.display_channels+1))
            fcn_update_axes(object)
            
        case 'downarrow'
            scale = get(handles.txt_scale, 'value');
            if scale <= 20
                value = scale * 2;
                set(handles.txt_scale, 'value', value);
            else
                value = scale + 20;
                set(handles.txt_scale, 'value', value);
            end
            
            set(handles.txt_scale, 'string', get(handles.txt_scale, 'value'));
            set(handles.main_ax, 'yLim', [get(handles.txt_scale, 'value')*-1, 0]*(EEG.ewa_montage.display_channels+1))
            fcn_update_axes(object)
    end

% check whether the ctrl is pressed also
elseif strcmp(event.Modifier, 'control')
    
    switch event.Key
        case 'c'
            %TODO: pop_up for channel number
            
        case 'uparrow'
            %             fprintf(1, 'more channels \n');
    end
    
end


function fcn_options(object, ~, type)
% get the handles
handles = guidata(object);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

switch type
    case 'disp_chans'
     
        answer = inputdlg('number of channels',...
            '', 1, {num2str( EEG.ewa_montage.display_channels )});

        % if different from previous
        if ~isempty(answer)
            newNumber = str2double(answer{1});
            if newNumber ~= EEG.ewa_montage.display_channels && newNumber <= length(EEG.ewa_montage.label_channels); 
                EEG.ewa_montage.display_channels = newNumber;
                % update the eeg structure before call
                setappdata(handles.fig, 'EEG', EEG);
                plot_initial_data(object)
            else
                fprintf(1, 'Warning: You requested more channels than available in the montage');
            end
        end
end

% Montage Functions
% ^^^^^^^^^^^^^^^^^
function fcn_montage_setup(object, ~)
% get the original figure handles
handles.ewa_plotter = guidata(object);
EEG = getappdata(handles.ewa_plotter.fig, 'EEG');

% make a window
% ~~~~~~~~~~~~~
handles.fig = figure(...
    'name',         'ewa montage setup',...
    'numberTitle',  'off',...
    'color',        [0.1, 0.1, 0.1],...
    'menuBar',      'none',...
    'units',        'normalized',...
    'outerPosition',[0 0.04 .8 0.96]);

% make the axes
% ~~~~~~~~~~~~~
% main axes
handles.main_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0.05 0.1, 0.6, 0.8]   ,...
    'nextPlot',     'add'                   ,...
    'color',        [0.2, 0.2, 0.2]         ,...
    'xcolor',       [0.9, 0.9, 0.9]         ,...
    'ycolor',       [0.9, 0.9, 0.9]         ,...
    'xtick',        []                      ,...    
    'ytick',        []                      ,...
    'fontName',     'Century Gothic'        ,...
    'fontSize',     8                       );

% montage table
handles.table = uitable(...
    'parent',       handles.fig             ,...
    'units',        'normalized'            ,...
    'position',     [0.7, 0.05, 0.25, 0.9]  ,...
    'backgroundcolor', [0.1, 0.1, 0.1; 0.2, 0.2, 0.2],...
    'foregroundcolor', [0.9, 0.9, 0.9]      ,...
    'columnName',   {'name','chn','ref'},...
    'columnEditable', [true, true, true]);

% create the buttons
handles.button_delete = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'push',...    
    'String',   'delete',...
    'ForegroundColor', 'k',...
    'Units',    'normalized',...
    'Position', [0.75 0.075 0.05 0.02],...
    'FontName', 'Century Gothic',...
    'FontWeight', 'bold',...   
    'FontSize', 10);

set(handles.button_delete, 'callback', {@fcn_button_delete});

handles.button_apply = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'push',...    
    'String',   'apply',...
    'ForegroundColor', 'k',...
    'Units',    'normalized',...
    'Position', [0.85 0.075 0.05 0.02],...
    'FontName', 'Century Gothic',...
    'FontWeight', 'bold',...   
    'FontSize', 10);

set(handles.button_apply, 'callback', {@fcn_button_apply});

% set the initial table values
data = cell(length(EEG.ewa_montage.label_channels), 3);
% current montage
data(:,1) = deal(EEG.ewa_montage.label_channels);
data(:,[2,3]) = num2cell(EEG.ewa_montage.channels);

% put the data into the table
set(handles.table, 'data', data);

% update handle structure
guidata(handles.fig, handles);

% plot the net
plot_net(handles.fig)


function plot_net(montage_handle)
% get the handles and EEG structure
handles  = guidata(montage_handle);
EEG = getappdata(handles.ewa_plotter.fig, 'EEG');

if ~isfield(EEG.chanlocs(1), 'x')
   EEG.chanlocs = swa_add2dlocations(EEG.chanlocs); 
end

x = [EEG.chanlocs.x];
y = [EEG.chanlocs.y];
labels = {EEG.chanlocs.labels};

% make sure the circles are in the lines
set(handles.main_ax, 'xlim', [0, 41], 'ylim', [0, 41]);

for n = 1:length(EEG.chanlocs)
    handles.plt_markers(n) = plot(handles.main_ax, y(n), x(n),...
        'lineStyle', 'none',...
        'lineWidth', 3,...
        'marker', 'o',...
        'markersize', 25,...
        'markerfacecolor', [0.15, 0.15, 0.15],...
        'markeredgecolor', [0.08, 0.08, 0.08],...
        'selectionHighlight', 'off',...
        'userData', n);
    
    handles.txt_labels(n) = text(...
        y(n), x(n), labels{n},...
        'parent', handles.main_ax,...
        'fontname', 'liberation sans narrow',...
        'fontsize',  8,...
        'fontweight', 'bold',...
        'color',  [0.9, 0.9, 0.9],...
        'horizontalAlignment', 'center',...
        'selectionHighlight', 'off',...
        'hitTest', 'off');
end

set(handles.plt_markers, 'ButtonDownFcn', {@bdf_select_channel});

guidata(handles.fig, handles);
setappdata(handles.ewa_plotter.fig, 'EEG', EEG);

update_net_arrows(handles.fig)


function update_net_arrows(montage_handle)
% get the handles and EEG structure
handles     = guidata(montage_handle);
EEG         = getappdata(handles.ewa_plotter.fig, 'EEG');

x = [EEG.chanlocs.x];
y = [EEG.chanlocs.y];

if isfield(handles, 'line_arrows')
    try
        delete(handles.line_arrows);
    end
end

% get the table data
data = get(handles.table, 'data');

% make an arrow from each channel to each reference
for n = 1:size(data, 1)
    handles.line_arrows(n) = line([y(data{n,2}), y(data{n,3})],...
                                  [x(data{n,2}), x(data{n,3})],...
                                  'parent', handles.main_ax,...
                                  'color', [0.3, 0.8, 0.3]);
end

uistack(handles.plt_markers, 'top');
uistack(handles.txt_labels, 'top');

guidata(handles.fig, handles);


function bdf_select_channel(object, ~)
% get the handles
handles = guidata(object);

% get the mouse button
event = get(handles.fig, 'selectionType');
ch    = get(object, 'userData');  

switch event
    case 'normal'
        data = get(handles.table, 'data');
        data{end+1, 1} = [num2str(ch), ' - '];
        data{end, 2} = ch;
        set(handles.table, 'data', data);
        
    case 'alt'
        data = get(handles.table, 'data');
        ind  = cellfun(@(x) isempty(x), data(:,3));
        data(ind,3) = deal({ch});
        set(handles.table, 'data', data);
        
        % replot the arrows
        update_net_arrows(handles.fig)
end


function fcn_button_delete(object, ~)
% get the handles
handles = guidata(object);

% find the row indices to delete
jscroll = findjobj(handles.table);
del_ind = jscroll.getComponent(0).getComponent(0).getSelectedRows+1;

% get the table, delete the rows and reset the table
data = get(handles.table, 'data');
data(del_ind, :) = [];
set(handles.table, 'data', data);

% update the arrows on the montage plot
update_net_arrows(handles.fig)


function fcn_button_apply(object, ~)
% get the montage handles
handles = guidata(object);
EEG         = getappdata(handles.ewa_plotter.fig, 'EEG');

% get the table data
data = get(handles.table, 'data');

% check the all inputs are valid
if any(any(cellfun(@(x) ~isa(x, 'double'), data(:,[2,3]))))
    fprintf(1, 'Warning: check that all channel inputs are numbers\n');
end

EEG.ewa_montage.label_channels  = data(:,1);
EEG.ewa_montage.channels        = cell2mat(data(:,[2,3]));

if length(EEG.ewa_montage.label_channels) < EEG.ewa_montage.display_channels
    EEG.ewa_montage.display_channels = length(EEG.ewa_montage.label_channels);
    fprintf(1, 'Warning: reduced number of display channels to match montage\n');
end

guidata(handles.fig, handles);
setappdata(handles.ewa_plotter.fig, 'EEG', EEG);

plot_initial_data(handles.ewa_plotter.fig);