function ewa_eeg_plotter()

%TODO: Main page 
        %Montage channel names on left accompanied with a small button to hide that channel
        %Scale - green lines across one of the channels
        %Video scroll with space bar - reasonable speed - pause/play?
        %Auto adjust time scale on bottom for whole night
        %main axis in seconds
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

% create the menu bar
% ~~~~~~~~~~~~~~~~~~~
handles.menu.file       = uimenu(handles.fig, 'label', 'file');
handles.menu.load       = uimenu(handles.menu.file,...
    'Label', 'load eeg',...
    'Accelerator', 'L');
handles.menu.save       = uimenu(handles.menu.file,...
    'Label', 'save eeg',...
    'Accelerator', 'S');

handles.menu.montage    = uimenu(handles.fig, 'label', 'montage', 'enable', 'off');

handles.menu.options    = uimenu(handles.fig, 'label', 'options');

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
set(handles.menu.load, 'callback', {@fcn_load_eeg})
set(handles.menu.montage, 'callback', {@fcn_montage_setup})

set(handles.fig,...
    'KeyPressFcn', {@cb_key_pressed,});

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
    EEG.ewa_montage.epoch_length    = 30;
    EEG.ewa_montage.no_channels     = 12;
    EEG.ewa_montage.channels(:,1)   = [1:EEG.ewa_montage.no_channels]';
    EEG.ewa_montage.channels(:,2)   = size(eegData, 1);
    EEG.ewa_montage.filter_options  = [0.5; 30]';
end
    
% update the handles structure
guidata(handles.fig, handles)
% use setappdata for data storage to avoid passing it around in handles when not necessary
setappdata(handles.fig, 'EEG', EEG);
setappdata(handles.fig, 'eegData', eegData);

% plot the initial data
plot_initial_data(handles.fig)


function plot_initial_data(object)
% get the handles structure
handles = guidata(object);

% get the data
EEG = getappdata(handles.fig, 'EEG');
eegData = getappdata(handles.fig, 'eegData');

% select the plotting data
range = 1:EEG.ewa_montage.epoch_length*EEG.srate;
data = eegData(EEG.ewa_montage.channels(:,1), range) - eegData(EEG.ewa_montage.channels(:,2), range);

% filter the data
% ~~~~~~~~~~~~~~~
[EEG.filter.b, EEG.filter.a] = ...
        butter(2,[EEG.ewa_montage.filter_options(1)/(EEG.srate/2),...
                  EEG.ewa_montage.filter_options(2)/(EEG.srate/2)]);
data = single(filtfilt(EEG.filter.b, EEG.filter.a, double(data'))'); %transpose data twice

% plot the data
% ~~~~~~~~~~~~~
% define accurate spacing
scale = get(handles.txt_scale, 'value');
toAdd = [1:EEG.ewa_montage.no_channels]'*scale;
toAdd = repmat(toAdd, [1, length(range)]);

% space out the data for the single plot
data = data+toAdd;

set(handles.main_ax, 'yLim', [0 scale]*(EEG.ewa_montage.no_channels+1))

handles.plot_eeg = line(range, data,...
                        'color', [0.9, 0.9, 0.9],...
                        'parent', handles.main_ax);

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
range = current_point:current_point+EEG.ewa_montage.epoch_length*EEG.srate-1;
data = eegData(EEG.ewa_montage.channels(:,1), range) - eegData(EEG.ewa_montage.channels(:,2), range);

data = single(filtfilt(EEG.filter.b, EEG.filter.a, double(data'))'); %transpose data twice

% plot the data
% ~~~~~~~~~~~~~
% define accurate spacing
scale = get(handles.txt_scale, 'value');
toAdd = [1:EEG.ewa_montage.no_channels]'*scale;
toAdd = repmat(toAdd, [1, length(range)]);

% space out the data for the single plot
data = data+toAdd;

for n = 1:EEG.ewa_montage.no_channels
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


function cb_key_pressed(object, event)
% get the relevant data
handles = guidata(object);
EEG = getappdata(handles.fig, 'EEG');

% movement keys
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
            set(handles.txt_scale, 'value', scale / 2);
        else
            set(handles.txt_scale, 'value', scale - 20);
        end
        set(handles.txt_scale, 'string', get(handles.txt_scale, 'value'));
        set(handles.main_ax, 'yLim', [0 get(handles.txt_scale, 'value')]*(EEG.ewa_montage.no_channels+1))
        fcn_update_axes(object)

    case 'downarrow'
        scale = get(handles.txt_scale, 'value');
        if scale <= 20
            set(handles.txt_scale, 'value', scale * 2);
        else
            set(handles.txt_scale, 'value', scale + 20);
        end
        set(handles.txt_scale, 'string', get(handles.txt_scale, 'value'));
        set(handles.main_ax, 'yLim', [0 get(handles.txt_scale, 'value')]*(EEG.ewa_montage.no_channels+1))
        fcn_update_axes(object)

end


function fcn_montage_setup(object, ~)
% get the original figure handles
ohandles = guidata(object);
EEG = getappdata(ohandles.fig, 'EEG');

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
data = cell(EEG.ewa_montage.no_channels,3);
% current montage
data(:,1) = deal({'undefined'});
data(:,[2,3]) = num2cell(EEG.ewa_montage.channels);

% put the data into the table
set(handles.table, 'data', data);

% update handle structure
handles.original = ohandles.fig;
guidata(handles.fig, handles);

% plot the net
plot_net(handles.fig, ohandles.fig)


function plot_net(montage_handle, original_handle)
% get the handles and EEG structure
handles  = guidata(montage_handle);
ohandles = guidata(original_handle);
EEG = getappdata(ohandles.fig, 'EEG');

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
setappdata(ohandles.fig, 'EEG', EEG);

update_net_arrows(handles.fig, ohandles.fig)


function update_net_arrows(montage_handle, original_handle)
% get the handles and EEG structure
handles     = guidata(montage_handle);
ohandles    = guidata(original_handle);
EEG         = getappdata(ohandles.fig, 'EEG');

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
        update_net_arrows(handles.fig, handles.original)
end


function fcn_button_delete(object, ~)
% get the handles
handles = guidata(object);

% find the row indices to delete
jscroll = findjobj(handles.table);
del_ind = jscroll.getComponent(0).getComponent(0).getSelectedRows+1;

data = get(handles.table, 'data');
data(del_ind, :) = [];
set(handles.table, 'data', data);


function fcn_button_apply(object, ~)
