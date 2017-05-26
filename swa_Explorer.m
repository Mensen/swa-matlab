% GUI for Exploring Travelling Waves
function swa_Explorer(varargin)
DefineInterface

function DefineInterface
% Create Figure

% Dual monitors creates an issue in Linux environments whereby the two
% screens are seen as one long screen, so always use first one
sd = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment.getScreenDevices;
if length(sd) > 1
    bounds = sd(2).getDefaultConfiguration.getBounds;
    figPos = [bounds.x bounds.y bounds.width bounds.height];
else
    bounds = sd(1).getDefaultConfiguration.getBounds;
    figPos = [bounds.x bounds.y bounds.width bounds.height];
end

handles.fig = figure(...
    'Name',         'Travelling Waves:',...
    'NumberTitle',  'off',...
    'Color',        'w',...
    'MenuBar',      'none',...
    'Units',        'pixels',...
    'Outerposition',figPos);

set(handles.fig,...
    'KeyPressFcn', {@cb_KeyPressed});


% Menus
% ^^^^^
handles.menu.File = uimenu(handles.fig, 'Label', 'File');
handles.menu.LoadData = uimenu(handles.menu.File,...
    'Label', 'Load Data',...
    'Accelerator', 'L');
set(handles.menu.LoadData, 'Callback', {@menu_LoadData});

handles.menu.SaveData = uimenu(handles.menu.File,...
    'Label', 'Save Data',...
    'Accelerator', 'S');
set(handles.menu.SaveData, 'Callback', {@menu_SaveData});

% view menu
handles.menu.View = uimenu(handles.fig, 'label', 'View');
handles.menu.filter_toggle = uimenu(handles.menu.View, ...
    'label', 'filter toggle', ...
    'checked', 'on', ...
    'callback', {@fcn_options, 'filter_toggle'});


% Plot Titles and Export Button
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
handles.Title_SWPlot = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'text',...    
    'String',   'Individual Wave',...
    'Units',    'normalized',...
    'Position', [0.05 .68 0.4 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
handles.Ex_SWPlot = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'pushbutton',...    
    'String',   '+',...
    'Units',    'normalized',...
    'Position', [0.43 .68 0.02 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
set(handles.Ex_SWPlot, 'Callback', @edit_SWPlot)

handles.Title_Delay = uicontrol(...
    'Parent',   handles.fig,...    
    'value', 1 ,...
    'Style',    'text',...    
    'Units',    'normalized',...
    'Position', [0.5 .73 0.45 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);


handles.Ex_Delay = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'pushbutton',...    
    'String',   '+',...
    'Units',    'normalized',...
    'Position', [0.93 .73 0.02 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
set(handles.Ex_Delay, 'Callback', @pb_XDelay_Callback)

% csc plotter pushbutton
handles.Ex_Channel_Plot = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'pushbutton',...
    'String',   'csc',...
    'Units',    'normalized',...
    'Position', [0.93 0.925 0.02 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11,...
    'enable', 'off');
if exist('csc_eeg_plotter', 'file')
    set(handles.Ex_Channel_Plot, 'enable', 'on');
    set(handles.Ex_Channel_Plot, 'Callback', @pb_XChannel_Callback)
end


% Checkboxes for Delay
% ^^^^^^^^^^^^^^^^^^^^
% TODO: make single drop-down menu with checkboxes
handles.Surface_Delay = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'checkbox',...
    'BackgroundColor', 'w',...
    'String',   'Surface',...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.5 0.08 0.1 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
set(handles.Surface_Delay, 'Callback', @UpdateDelay2);

handles.Channels_Delay = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'checkbox',...    
    'BackgroundColor', 'w',...
    'String',   'Channels',...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.6 0.08 0.1 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
set(handles.Channels_Delay, 'Callback',  @UpdateDelay2);

handles.Origins_Delay = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'checkbox',... 
    'BackgroundColor', 'w',...
    'String',   'Origins',...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.7 0.08 0.1 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
set(handles.Origins_Delay, 'Callback',  @UpdateDelay2);

handles.Streams_Delay = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'checkbox',... 
    'BackgroundColor', 'w',...
    'String',   'Streams',...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.8 0.08 0.1 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
set(handles.Streams_Delay, 'Callback',  @UpdateDelay2);

% Checkboxes for wave plot
handles.cb_waveplot(1) = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'checkbox',...
    'BackgroundColor', 'w',...
    'String',   '<html>&#952</html>',...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.052 0.66 0.1 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);

handles.cb_waveplot(2) = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'checkbox',...
    'BackgroundColor', 'w',...
    'String',   '<html>&#945</html>',...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.052 0.63 0.1 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);


% Create Axes
% ^^^^^^^^^^^
handles.axes_eeg_channel(1) = axes(...
    'Parent', handles.fig,...
    'Position', [0.05 0.875 0.9 0.075],...
    'NextPlot', 'add',...
    'FontName', 'Century Gothic',...
    'FontSize', 8,...
    'box', 'off',...
    'Xtick', [],...
    'Ytick', []);

handles.axes_eeg_channel(2) = axes(...
    'Parent', handles.fig,...
    'Position', [0.05 0.8 0.9 0.075],...
    'NextPlot', 'add',...
    'FontName', 'Century Gothic',...
    'FontSize', 8,...
    'box', 'off',...
    'Ytick', []);

% button down function for both channel axes
set(handles.axes_eeg_channel, 'buttonDownFcn', {@btf_add_wave});

handles.axes_individual_wave = axes(...
    'Parent', handles.fig,...
    'Position', [0.05 0.4 0.4 0.3],...
    'FontName', 'Century Gothic',...
    'NextPlot', 'add',...
    'FontSize', 8,...
    'box', 'off',...
    'Xtick', []);

handles.ax_Delay = axes(...
    'Parent', handles.fig,...
    'Position', [0.5 0.1 0.45 0.65],...
    'NextPlot', 'add',...
    'FontName', 'Century Gothic',...
    'FontSize', 8,...
    'box', 'off',...
    'Xtick', [],...
    'Ytick', []);

% Two Wave Summary Plots
% ^^^^^^^^^^^^^^^^^^^^^^
% create the two axes
% ~~~~~~~~~~~~~~~~~~~
handles.ax_option(1) = axes(...
    'Parent', handles.fig,...
    'Position', [0.05 0.05 0.2 0.3],...
    'FontName', 'Century Gothic',...
    'FontSize', 8,...
    'box', 'off',...
    'Xtick', [],...
    'Ytick', []);

handles.ax_option(2) = axes(...
    'Parent', handles.fig,...
    'Position', [0.25 0.05 0.2 0.3],...
    'FontName', 'Century Gothic',...
    'FontSize', 8,...
    'box', 'off',...
    'Xtick', [],...
    'Ytick', []);

% export buttons
% ~~~~~~~~~~~~~~
handles.Ex_options(1) = uicontrol(...
    'Parent',       handles.fig         ,...   
    'Style',        'pushbutton'        ,...    
    'backgroundColor', [0.9, 0.9, 0.9]  ,...
    'foregroundColor', [0.1, 0.1, 0.1]  ,...
    'String',       '+'                 ,...
    'Units',        'normalized'        ,...
    'Position',     [0.23 .35 0.02 0.02],...
    'FontName',     'Century Gothic'    ,...
    'FontSize',     11                  );
set(handles.Ex_options(1), 'callback', {@pb_export_options, 1});

handles.Ex_options(2) = uicontrol(...
    'Parent',       handles.fig         ,...   
    'Style',        'pushbutton'        ,...    
    'backgroundColor', [0.9, 0.9, 0.9]  ,...
    'foregroundColor', [0.1, 0.1, 0.1]  ,...
    'String',       '+'                 ,...
    'Units',        'normalized'        ,...
    'Position',     [0.43 .35 0.02 0.02],...
    'FontName',     'Century Gothic'    ,...
    'FontSize',     11                  );
set(handles.Ex_options(2), 'callback', {@pb_export_options, 2});

% Context Menus
% ^^^^^^^^^^^^^
handles.menu.ButterflyContext = uicontextmenu;
handles.menu.UIContext_YReverse = uimenu(handles.menu.ButterflyContext,...
    'Label',    'Negative Down',...
    'Callback', {@fcn_context_axes_channel, 'normal'});
handles.menu.UIContext_YReverse = uimenu(handles.menu.ButterflyContext,...
    'Label',    'Negative Up',...
    'Callback', {@fcn_context_axes_channel, 'reverse'});
set(handles.axes_eeg_channel, 'uicontextmenu', handles.menu.ButterflyContext);
set(handles.axes_individual_wave, 'uicontextmenu', handles.menu.ButterflyContext);

% create the drop down menus
% ~~~~~~~~~~~~~~~~~~~~~~~~~~
% make the drop-down menus as java objects
[handles.java.options_list(1), handles.options_list(1)] = javacomponent(javax.swing.JComboBox);
set(handles.options_list(1),...
    'parent',   handles.fig,...      
    'units',    'normalized',...
    'position', [0.05 0.35 0.18 0.02],...
    'backgroundColor', [0.9, 0.9, 0.9]);
set(handles.java.options_list(1),...
    'ActionPerformedCallback', {@fcn_select_options, handles.fig, 1});

[handles.java.options_list(2), handles.options_list(2)] = javacomponent(javax.swing.JComboBox);
set(handles.options_list(2),...
    'parent',   handles.fig,...      
    'units',    'normalized',...
    'position', [0.25 0.35 0.18 0.02],...
    'backgroundColor', [0.9, 0.9, 0.9]);
set(handles.java.options_list(2),...
    'ActionPerformedCallback', {@fcn_select_options, handles.fig, 2});

% Status Bar
% ^^^^^^^^^^
handles.StatusBar = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'text',...    
    'String',   'Status Updates',...
    'Units',    'normalized',...
    'Position', [0 0 1 0.03],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);

handles.java.StatusBar = findjobj(handles.StatusBar); 

% set the alignment of the status bar
pause(0.5); drawnow % pause to let java objects load (reduces random java error)
handles.java.StatusBar.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handles.java.StatusBar.setHorizontalAlignment(javax.swing.SwingConstants.LEFT);

% Slider Spinner and Delete Button
[handles.java.Slider,handles.Slider] = javacomponent(javax.swing.JSlider);
set(handles.Slider,...
    'Parent',   handles.fig,...      
    'Units',    'normalized',...
    'Position', [0.05 0.72 0.32 0.05]);

% >> handles.java.Slider.set [then tab complete to find available methods]
handles.java.Slider.setBackground(javax.swing.plaf.ColorUIResource(1,1,1))
set(handles.java.Slider, 'MouseReleasedCallback',{@SliderUpdate, handles.fig});

[handles.java.Spinner,handles.Spinner] = javacomponent(javax.swing.JSpinner);
set(handles.Spinner,...
    'Parent',   handles.fig,...      
    'Units',    'normalized',...
    'Position', [0.38 0.72 0.05 0.05]);

% Set the font and size (Found through >>handles.java.Slider.Font)
handles.java.Spinner.setFont(javax.swing.plaf.FontUIResource('Century Gothic', 0, 25))
handles.java.Spinner.getEditor().getTextField().setHorizontalAlignment(javax.swing.SwingConstants.CENTER)
set(handles.java.Spinner, 'StateChangedCallback', {@SpinnerUpdate, handles.fig});

handles.pb_Delete = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'pushbutton',...    
    'String',   'X',...
    'Units',    'normalized',...
    'Position', [0.43 .72 0.02 0.05],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
set(handles.pb_Delete, 'Callback', {@pb_Delete_Callback});


% Channel Set ComboBoxes
% ^^^^^^^^^^^^^^^^^^^^^^
[handles.java.ChannelBox(1),handles.ChannelBox(1)] = javacomponent(javax.swing.JComboBox);
set(handles.ChannelBox(1),...
    'Parent',   handles.fig,...      
    'Units',    'normalized',...
    'Position', [0.02 0.90 0.03 0.02]);
set(handles.java.ChannelBox(1), 'ActionPerformedCallback', {@SpinnerUpdate, handles.fig});

[handles.java.ChannelBox(2),handles.ChannelBox(2)] = javacomponent(javax.swing.JComboBox);
set(handles.ChannelBox(2),...
    'Parent',   handles.fig,...      
    'Units',    'normalized',...
    'Position', [0.02 0.825 0.03 0.02]);  
set(handles.java.ChannelBox(2), 'ActionPerformedCallback', {@SpinnerUpdate, handles.fig});


% set java properties of Delay Combo box
[handles.java.PlotBox,handles.PlotBox] = javacomponent(javax.swing.JComboBox);
set(handles.PlotBox,...
    'Parent',   handles.fig,...      
    'Units',    'normalized',...
    'Position', [0.65 0.73 0.15 0.02]);
handles.java.PlotBox.setModel(javax.swing.DefaultComboBoxModel({'Delay Map', 'Involvement Map'}));
handles.java.PlotBox.setFont(javax.swing.plaf.FontUIResource('Century Gothic', 0, 14));
set(handles.java.PlotBox, 'ActionPerformedCallback', {@SliderUpdate, handles.fig});


% Make Figure Visible and Maximise
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
jFrame = get(handle(handles.fig),'JavaFrame');
jFrame.setMaximized(true);   % to maximize the figure

% update the handles structure
guidata(handles.fig, handles);

function menu_LoadData(object, ~)
handles = guidata(object);

[swaFile, swaPath] = uigetfile('*.mat', 'Please Select the Results File');
if swaFile == 0
    set(handles.StatusBar, 'String', 'Information: No File Selected');
    return;
end

% Quick Check for right structures in file before loading
varnames = whos('-file', [swaPath,swaFile]);
if ~ismember('Data', {varnames.name}) || ~ismember('Info', {varnames.name})
    set(handles.StatusBar, 'String', 'Information: No Data or Info structure in file');
    return;
end    

% Load the data
loaded_file = load ([swaPath,swaFile]);

% Check for data present or external file
if ischar(loaded_file.Data.Raw)
    
    % check for changed reference
    if isfield (loaded_file.Info.Recording, 'new_reference')
        loaded_file.Info.Recording.dataDim(1) = ...
            loaded_file.Info.Recording.dataDim(1) ...
            + numel(loaded_file.Info.Recording.new_reference);
    end
    
    % default memory map data
    % TODO: make settable parameter
    flag_memory_map = true;
    
    % memory map or actually load the data
    if flag_memory_map
               
        data_file = loaded_file.Info.Recording.dataFile;
        
        temp_data = memmapfile(fullfile(swaPath, data_file), ...
            'format', {'single', loaded_file.Info.Recording.dataDim, 'eegData'});
        loaded_file.Data.Raw = temp_data.Data.eegData;
        
    else
        set(handles.StatusBar, 'String', 'Busy: Loading Data');
        fid = fopen(fullfile(swaPath, loaded_file.Data.Raw));
        
        loaded_file.Data.Raw = fread(fid, loaded_file.Info.Recording.dataDim, 'single');
        
        fclose(fid);
    end
end

% change data if reference was changed
if isfield (loaded_file.Info.Recording, 'new_reference')
    % get the new reference
    new_reference = loaded_file.Info.Recording.new_reference;
    
    % calculate the average mastoid activity
    reference_data = mean(loaded_file.Data.Raw(new_reference, :), 1);
    
    % rereference the data
    loaded_file.Data.Raw = loaded_file.Data.Raw ...
        - repmat(reference_data, [size(loaded_file.Data.Raw, 1), 1]);
    
    % remove the mastoid channels for the data set
    loaded_file.Data.Raw(new_reference, :) = [];
end

% Adjust settings dependent on wave types
if isfield(loaded_file, 'SW')
    handles.SW = loaded_file.SW;
    handles.SW_Type = 'SW';
elseif isfield(loaded_file, 'ST')
    handles.SW = loaded_file.ST;
    handles.SW_Type = 'ST';
elseif isfield(loaded_file, 'SS')
    handles.SW = loaded_file.SS;
    handles.SW_Type = 'SS';
    % no delay maps for spindles
    handles.java.PlotBox.setSelectedIndex(1);
    % checkboxes for power and reference
    set(handles.cb_waveplot(1),...
        'String',   'canonical');
    set(handles.cb_waveplot(2),...
        'String',   'power');
else
    set(handles.StatusBar, 'String', 'Information: No SW/ST/SS structure in file');
    return;
end

% place the Info struct in the GUI handles
handles.Info    = loaded_file.Info;

% set the figure title to match the file name
set(handles.fig, 'Name', ['Travelling Waves: ', swaFile]);

% Set the ComboBoxes
% ``````````````````
channel_list = [{handles.Info.Electrodes.labels}, {'All', 'Ref'}];

% create java models using swing
java_model1 = javax.swing.DefaultComboBoxModel(channel_list);
java_model2 = javax.swing.DefaultComboBoxModel(channel_list);

handles.java.ChannelBox(1).setModel(java_model1);
handles.java.ChannelBox(1).setEditable(true);
handles.java.ChannelBox(2).setModel(java_model2);
handles.java.ChannelBox(2).setEditable(true);

    % handles.java.ChannelBox(1).getSelectedIndex() % Gets the value (setSele...)

% Set Slider and Spinner Values
% `````````````````````````````
handles.java.Slider.setValue(1);
handles.java.Slider.setMinimum(1);
handles.java.Slider.setMaximum(length(handles.SW));
handles.java.Slider.setMinorTickSpacing(5);
handles.java.Slider.setMajorTickSpacing(20);
handles.java.Slider.setPaintTicks(true);

% prepare filter for later
handles.filter_design = designfilt('lowpassiir', 'DesignMethod', 'cheby2', ...
    'StopbandFrequency', 20, 'PassbandFrequency', 16, ...
    'SampleRate', handles.Info.Recording.sRate);

% Update handles structure
guidata(handles.fig, handles);
setappdata(handles.fig, 'Data', loaded_file.Data);

% Set the output boxes
% ~~~~~~~~~~~~~~~~~~~~
% get the currently available options
options_list = swa_wave_summary('return options');

% check for wavetype since no travelling parameters are created for SS
if strcmp(handles.SW_Type, 'SS')
    bad_options = ismember(options_list,...
        {'distances', 'anglemap', 'topo_origins', ...
        'topo_streams', 'topo_meandelay', 'topo_streamorigins'});
    options_list(bad_options) = [];
end

% create and set the java models for the options list
model1 = javax.swing.DefaultComboBoxModel(options_list);
model2 = javax.swing.DefaultComboBoxModel(options_list);
handles.java.options_list(1).setModel(model1);
handles.java.options_list(2).setModel(model2);

% set the second option box to the second value (0-index value 1)
handles.java.options_list(2).setSelectedIndex(1)

% plot the first two output parameters in the list
fcn_select_options([],[], handles.fig, 1);
fcn_select_options([],[], handles.fig, 2);

% set the spinner value which initiates other plot updates
handles.java.Spinner.setValue(1);

set(handles.StatusBar, 'String', 'Idle');

function menu_SaveData(hObject, ~)
% get the GUI handles
handles = guidata(hObject);

% get the data
Data = getappdata(handles.fig, 'Data');

% get user input for the save name and path
[saveName,savePath] = uiputfile('*.mat');

% check if the cancel button was selected
if saveName == 0; return; end

% get the Info alone to save as is
Info = handles.Info;

% get the correct SW type before saving specifically
switch handles.SW_Type
    case 'SW'
        SW = handles.SW;
    case 'SS'
        SS   = handles.SW;
    case 'ST'
        ST  = handles.SW;
end

% save the data
switch handles.SW_Type
    case 'SW'
        
        swa_saveOutput(Data, Info, SW, fullfile(savePath, saveName), 1, 0);
        
    case 'ST'
        
        swa_saveOutput(Data, Info, ST, fullfile(savePath, saveName), 1, 0);
        
    otherwise
        % TODO: use swa_saveOutput for SS and ST as well
        save(fullfile(savePath, saveName), 'Data', 'Info', handles.SW_Type, '-mat');
end

set(handles.fig, 'Name', ['Traveling Waves: ', saveName]);


% Update Controls
function SpinnerUpdate(~, ~, hObject)
handles = guidata(hObject); % Needs to be like this because slider is a java object

% check if function called with loaded data
if ~isfield(handles, 'SW')
    return;
end

if handles.java.Spinner.getValue() == 0
    handles.java.Spinner.setValue(1);
    return;
elseif handles.java.Spinner.getValue() > length(handles.SW)
    handles.java.Spinner.setValue(length(handles.SW));
    return;    
end

handles.java.Slider.setValue(handles.java.Spinner.getValue())

% update the plots
handles = update_SWPlot(handles);
handles = update_axes_channels(handles);
handles = update_SWDelay(handles, 0);

guidata(hObject, handles);

function SliderUpdate(~,~,Figure)
handles = guidata(Figure); % Needs to be like this because slider is a java object

% check if function called with loaded data
if ~isfield(handles, 'SW')
    return;
end

handles.java.Spinner.setValue(handles.java.Slider.getValue())

% Update the plots (except origins and density since they are global)
handles = update_axes_channels(handles);
handles = update_SWPlot(handles);
handles = update_SWDelay(handles, 0);

guidata(handles.fig, handles);

function cb_KeyPressed(object, eventdata)
% get the GUI figure handles
handles = guidata(object);

% initial plot then update the yData in a loop (faster than replot)
nSW = handles.java.Spinner.getValue();

% movement keys
switch eventdata.Key
    case 'rightarrow'
        % move to the next wave if not at the end
        if nSW < handles.java.Slider.getMaximum
            handles.java.Spinner.setValue(nSW+1);
        end
    case 'leftarrow'
        if nSW > 1
            handles.java.Spinner.setValue(nSW-1);
        end
end


% Plot Controls
function handles = update_axes_channels(handles)

% get the data structure
Data = getappdata(handles.fig, 'Data');

% get current wave
nSW = handles.java.Spinner.getValue();

% Calculate the range / wave peaks and start points
switch handles.SW_Type
    case {'SW', 'ST'}
        winLength = floor(15 * handles.Info.Recording.sRate);
        range = handles.SW(nSW).Ref_PeakInd - winLength  ...
            :  handles.SW(nSW).Ref_PeakInd + winLength;
        % calculate points for arrows and zoom lines
        wave_peaks = [handles.SW.Ref_PeakInd]./ handles.Info.Recording.sRate;
        start_point = handles.SW(nSW).Ref_PeakInd / handles.Info.Recording.sRate;
        end_point = handles.SW(nSW).Ref_PeakInd / handles.Info.Recording.sRate;
    case 'SS'
        winLength = floor((30 * handles.Info.Recording.sRate - handles.SW(nSW).Ref_Length) / 2);
        range = handles.SW(nSW).Ref_Start - winLength  :  handles.SW(nSW).Ref_End + winLength;
        
        wave_peaks = ([handles.SW.Ref_Start] + [handles.SW.Ref_Length]./ ...
            2) / handles.Info.Recording.sRate;
        start_point = handles.SW(nSW).Ref_Start / handles.Info.Recording.sRate;
        end_point = handles.SW(nSW).Ref_End / handles.Info.Recording.sRate;
end

% check that the range is within data limits (set to sample 1 if not)
range(range < 1 | range > size(Data.Raw, 2)) = 1;
xaxis = range./handles.Info.Recording.sRate;

% check for special selected channels
data_to_plot = cell(2, 1);
for n = 1:2
    selected_label = handles.java.ChannelBox(n).getSelectedItem;
    
    if strcmp(selected_label, 'All')
        data_to_plot{n} = Data.Raw(:, range);
        
    elseif strcmp(selected_label, 'Ref')
        % check which reference wave to plot
        switch handles.SW_Type
            case 'SW'
                data_to_plot{n} = mean(Data.SWRef(:, range), 1);
            case 'SS'
                data_to_plot{n} = mean(Data.SSRef(:, range), 1);
            case 'ST'
                data_to_plot{n} = mean(Data.STRef(:, range), 1);
        end
        
    else
        % - channel selected (most cases) - %
        Ch = handles.java.ChannelBox(n).getSelectedIndex() + 1;
        data_to_plot{n} = Data.Raw(Ch, range);
    end
end

% check for filter toggle
if strcmp(get(handles.menu.filter_toggle, 'checked'), 'on')
    for n = 1 : 2
        data_to_plot{n} = filtfilt(...
            handles.filter_design, double(data_to_plot{n})')';
    end
end


% define plot_method
if ~isfield(handles, 'lines_eeg_channel')
    plot_method = 'initial';
else
    if length(handles.lines_eeg_channel{1}) == size(data_to_plot{1}, 1) ...
       && length(handles.lines_eeg_channel{2}) == size(data_to_plot{2}, 1)
        plot_method = 'replot';
    else
        delete(handles.lines_eeg_channel{1});
        delete(handles.lines_eeg_channel{2});
        handles = rmfield(handles, 'lines_eeg_channel');
        plot_method = 'initial';
    end  
end

switch plot_method
    case 'initial'
        % -- initial Plot (50 times takes 1.67s) -- %
        % plot the top raw eeg
        handles.lines_eeg_channel{1} = plot(handles.axes_eeg_channel(1), xaxis, data_to_plot{1}', 'k');
        handles.lines_eeg_channel{2} = plot(handles.axes_eeg_channel(2), xaxis, data_to_plot{2}', 'k');
        
        % set the top axes limits
        deviation = double(std(data_to_plot{1}));
        set(handles.axes_eeg_channel,...
            'yLim', [-5 * deviation, 5 * deviation],...
            'xLim', [xaxis(1), xaxis(end)]);
               
        % plot the two zoom lines
        handles.zoomline(1) = line([start_point - 0.5, start_point - 0.5], [-200, 200]);
        handles.zoomline(2) = line([end_point + 0.5, end_point + 0.5], [-200, 200]);
        
        % set common zoomline parameters
        set(handles.zoomline,...
            'color', [0.4 0.4 0.4] ,...
            'linewidth', 2 ,...
            'Parent', handles.axes_eeg_channel(1));
        
        % Just plot all the arrows already
        handles.arrows_Butterfly = text(wave_peaks, ones(1, length(wave_peaks)) * 5 * deviation ,...
            '\downarrow',...
            'FontSize', 20 ,...
            'HorizontalAlignment', 'center' ,...
            'Clipping', 'on',...
            'Parent', handles.axes_eeg_channel(1));
        
    case 'replot'
        % -- re-plotting (50 times takes 0.3s) -- %
        % loop each axes
        for a = 1:2
            set(handles.lines_eeg_channel{a}, 'xData', xaxis);
            
            % loop for each channel (only more than 1 for All or Ref)
            for n = 1:size(data_to_plot{a}, 1)
                set(handles.lines_eeg_channel{a}(n), 'yData', data_to_plot{a}(n,:)');
            end
        end
        
        % change the x limits for the channels
        set(handles.axes_eeg_channel,...
            'XLim', [xaxis(1), xaxis(end)]);
        
        % shift the zoom lines
        set(handles.zoomline(1), 'xData',...
            [start_point - 0.5, start_point - 0.5]);
        set(handles.zoomline(2), 'xData',...
            [end_point + 0.5, end_point + 0.5]);
end

function handles = update_SWPlot(handles)

% get the data structure
Data = getappdata(handles.fig, 'Data');

% get the current wave number
nSW = handles.java.Spinner.getValue();

% Calculate the range
switch handles.SW_Type
    case 'SW'
        winLength = floor(2 * handles.Info.Recording.sRate);
        range = handles.SW(nSW).Ref_PeakInd - winLength  :  handles.SW(nSW).Ref_PeakInd + winLength;
    case 'SS'
        winLength = floor((2 * handles.Info.Recording.sRate - handles.SW(nSW).Ref_Length) / 2);
        range = handles.SW(nSW).Ref_Start - winLength  :  handles.SW(nSW).Ref_End + winLength;
    case 'ST'
        winLength = floor(1 * handles.Info.Recording.sRate);
        range = handles.SW(nSW).Ref_PeakInd - winLength  :  handles.SW(nSW).Ref_PeakInd + winLength;
end

% check that the range is within data limits (set to sample 1 if not)
range(range < 1 | range > size(Data.Raw, 2)) = 1;

% check for filter toggle
if strcmp(get(handles.menu.filter_toggle, 'checked'), 'off')
    data_to_plot = Data.Raw(:, range);
else
    data_to_plot = filtfilt(...
        handles.filter_design, double(Data.Raw(:, range))')';    
end

% initial plot
% ^^^^^^^^^^^^
% check if the plot already exists
if ~isfield(handles, 'SWPlot') 
    cla(handles.axes_individual_wave);
    
    % plot all the channels but hide them
    handles.SWPlot.All = plot(handles.axes_individual_wave, data_to_plot',...
        'color', [0.6 0.6 0.6],...
        'linewidth', 1,...
        'visible', 'off');
    
    % plot the reference wave
    handles.SWPlot.Ref = plot(handles.axes_individual_wave, Data.([handles.SW_Type, 'Ref'])(handles.SW(nSW).Ref_Region(1), range)',...
        'color', 'r',...
        'linewidth', 3);
    
    % plot wavelets
    switch handles.SW_Type
        case 'SS'
            % find the maximum point in the actual data to scale the wavelet power
            data_max = ceil(abs(max(max(...
                Data.Raw(handles.SW(nSW).Channels_Active, range))))...
                / 10) * 10 + 10;
            data = Data.CWT(handles.SW(nSW).Ref_Region(1), range);
            handles.SWPlot.CWT(1) = plot(handles.axes_individual_wave,...
                (data./max(data) * data_max) - data_max,...
                'color', 'b',...
                'linewidth', 1);
        case 'ST'
            % check if the wave plot check boxes are active
            if get(handles.cb_waveplot(1), 'value')
                handles.SWPlot.CWT(1) = plot(handles.axes_individual_wave,...
                    Data.CWT{1}(handles.SW(nSW).Ref_Region(1), range)',...
                    'color', 'b',...
                    'linewidth', 1);
                handles.SWPlot.CWT(2) = plot(handles.axes_individual_wave,...
                    Data.CWT{2}(handles.SW(nSW).Ref_Region(1), range)',...
                    'color', 'g',...
                    'linewidth', 1);
            end
    end
    
    % set only the active channels to visible
    set(handles.SWPlot.All(handles.SW(nSW).Channels_Active),...
        'visible', 'on');
    % adjust the x-axes to match range length
    set(handles.axes_individual_wave, 'xLim', [1, length(range)])

% update plot
% ^^^^^^^^^^^^    
else
    for n = 1:size(Data.Raw,1)
        set(handles.SWPlot.All(n),...
            'yData', data_to_plot(n, :),...
            'color', [0.6 0.6 0.6],...
            'linewidth', 1,...
            'visible', 'off');
    end
    
    set(handles.SWPlot.All(handles.SW(nSW).Channels_Active),...
        'visible', 'on');
    
    set(handles.SWPlot.Ref,...
        'yData', Data.([handles.SW_Type, 'Ref'])(handles.SW(nSW).Ref_Region(1), range));
    
    % Find the absolute maximum value and round to higher 10, then add 10 for space
    data_max = ceil(abs(max(max(Data.Raw(handles.SW(nSW).Channels_Active, range))))/10)*10+10;
    set(handles.axes_individual_wave, 'yLim', [-data_max, data_max])
    
    % update the cwt data...
    switch handles.SW_Type
        case 'SS'
                data = Data.CWT(handles.SW(nSW).Ref_Region(1),range);
                set(handles.SWPlot.CWT(1),...
                    'yData', (data./max(data) * data_max) - data_max);
        case 'ST'
            % check if the wave plot check boxes are active
            if get(handles.cb_waveplot(1), 'value')
                set(handles.SWPlot.CWT(1),...
                    'yData', Data.CWT{1}(handles.SW(nSW).Ref_Region(1), range));
                set(handles.SWPlot.CWT(2),...
                    'yData', Data.CWT{2}(handles.SW(nSW).Ref_Region(1), range));
            end
    end
end

function handles = update_SWDelay(handles, nFigure)
% plot the delay/involvement map

% get the current wave number
nSW = handles.java.Spinner.getValue();

% clear the axes for a new plot
if nFigure ~= 1; 
    cla(handles.ax_Delay); 
end

% check for grid size parameter to create maps
if ~isfield(handles.Info.Parameters, 'Travelling_GS')
    handles.Info.Parameters.Travelling_GS = 40;
end

% plot the Delay Map...
if handles.java.PlotBox.getSelectedIndex() + 1 == 1

    % take the delay map from the SW structure if possible
    if ~isempty(handles.SW(nSW).Travelling_DelayMap)
        H = swa_Topoplot...
            (handles.SW(nSW).Travelling_DelayMap, handles.Info.Electrodes,...
            'NewFigure',        nFigure                             ,...
            'Axes',             handles.ax_Delay                    ,...
            'NumContours',      10                                  ,...
            'PlotContour',      1                                   ,...
            'PlotSurface',      get(handles.Surface_Delay,  'value'),...
            'PlotChannels',     get(handles.Channels_Delay, 'value'),...
            'PlotStreams',      get(handles.Streams_Delay,  'value'),...
            'Streams',          handles.SW(nSW).Travelling_Streams);
        
    % if there is no delay map make one   
    else 
        H = swa_Topoplot...
            ([],                handles.Info.Electrodes,            ...
            'Data',             handles.SW(nSW).Travelling_Delays   ,...
            'GS',               handles.Info.Parameters.Travelling_GS,...
            'NewFigure',        nFigure                             ,...
            'Axes',             handles.ax_Delay                    ,...
            'NumContours',      10                                  ,...
            'PlotContour',      1                                   ,...
            'PlotSurface',      get(handles.Surface_Delay,  'value'),...
            'PlotChannels',     get(handles.Channels_Delay, 'value'),...
            'PlotStreams',      get(handles.Streams_Delay,  'value'),...
            'Streams',          handles.SW(nSW).Travelling_Streams);
    end
    
    if get(handles.Origins_Delay, 'Value') == 1 && exist('H', 'var')
        if isfield(H, 'Channels')
            set(H.Channels(handles.SW(nSW).Travelling_Delays<2),...
                'String',           'o'         ,...
                'FontSize',         12          );
        end
    end

% Or plot the involvement map (peak 2 peak amplitudes for active channels
elseif handles.java.PlotBox.getSelectedIndex() + 1 == 2;   
    
    % plot different data for various wavetypes
    switch handles.SW_Type
        case 'SW'
            data_to_plot = handles.SW(nSW).Channels_NegAmp;
        case {'SS', 'ST'}
            data_to_plot = handles.SW(nSW).Channels_Power;
            handles.SW(nSW).Travelling_Streams = [];
    end
    
    swa_Topoplot...
        ([],                handles.Info.Electrodes             ,...
        'Data',             data_to_plot                        ,...
        'GS',               handles.Info.Parameters.Travelling_GS,...
        'NewFigure',        nFigure                             ,...
        'Axes',             handles.ax_Delay                    ,...
        'NumContours',      10                                  ,...
        'PlotContour',      1                                   ,...
        'PlotSurface',      get(handles.Surface_Delay,  'value'),...
        'PlotChannels',     get(handles.Channels_Delay, 'value'),...
        'PlotStreams',      get(handles.Streams_Delay,  'value'),...
        'Streams',          handles.SW(nSW).Travelling_Streams);
    
end

function fcn_select_options(~, ~, object, no_axes)
% function to change the summary plot displayed

% get the handles from the figure
handles = guidata(object);

% if handles is empty, return
if ~isfield(handles, 'SW')
    return
end

% clear whatever is on the current axes
cla(handles.ax_option(no_axes), 'reset');

% get the selected option
type = handles.java.options_list(no_axes).getSelectedItem;

% draw the selected summary statistic on the axes
swa_wave_summary(handles.SW, handles.Info,...
    type, 1, handles.ax_option(no_axes));


% Push Buttons
function pb_XDelay_Callback(hObject, ~)
handles = guidata(hObject);
update_SWDelay(handles, 1);

function pb_Delete_Callback(hObject, ~)
% function to delete an entire wave from the SW structure and redraw the
% plots

% get the gui handles
handles = guidata(hObject);

% get the current wave
nSW = handles.java.Spinner.getValue();

% delete the wave from the handles structure
handles.SW(nSW)=[];

% reset the maximum of the slider
handles.java.Slider.setMaximum(length(handles.SW));

% delete the arrow on the butterfly plot then the handle
delete(handles.arrows_Butterfly(nSW));
handles.arrows_Butterfly(nSW) = [];

% update the handles structure
guidata(hObject, handles);

% update the spinner which updates the plots
SpinnerUpdate([],[], hObject);

% update the wave summary plots
fcn_select_options([],[], handles.fig, 1);
fcn_select_options([],[], handles.fig, 2);

function pb_export_options(object, ~, axes_number)

% get the gui handles
handles = guidata(object);

% get the selected option
type = handles.java.options_list(axes_number).getSelectedItem;

% draw the selected summary statistic on the axes
swa_wave_summary(handles.SW, handles.Info,...
    type, 1);

function pb_XChannel_Callback(object, ~)

% get the gui handles
handles = guidata(object);

% get the name of the original set file
set_file = [handles.Info.Recording.dataFile(1 : end-3), 'set'];

% load the EEG (might be inefficient since data is already loaded from swa)
EEG = pop_loadset(set_file);

% check for new reference
EEG = pop_reref(EEG, [handles.Info.Recording.new_reference]);

% delete csc info if present
if isfield(EEG, 'csc_event_data')
    EEG = rmfield(EEG, {'csc_montage', 'csc_event_data'});
end

% create the current saw tooth waves as events
% pre-allocate the event data
no_events = length(handles.SW);
EEG.csc_event_data = cell(sum(no_events), 3);

% deal standard names
[EEG.csc_event_data(:, 1)] = deal({'ST'});
[EEG.csc_event_data(:, 3)] = deal({2});

% get latencies into seconds
all_latencies = [handles.SW.Ref_PeakInd]' / EEG.srate;
[EEG.csc_event_data(:, 2)] = deal(num2cell(all_latencies));

EEG = csc_eeg_plotter(EEG);


% Manually Edit Waves
function edit_SWPlot(hObject, ~)
handles = guidata(hObject);

% get the data structure
Data = getappdata(handles.fig, 'Data');

% get the current wave number
nSW = handles.java.Spinner.getValue();

% Calculate the range
switch handles.SW_Type
    case 'SW'
        winLength = floor(2 * handles.Info.Recording.sRate);
        range = handles.SW(nSW).Ref_PeakInd - winLength  :  handles.SW(nSW).Ref_PeakInd + winLength;
    case 'SS'
        winLength = floor((2 * handles.Info.Recording.sRate - handles.SW(nSW).Ref_Length) / 2);
        range = handles.SW(nSW).Ref_Start - winLength  :  handles.SW(nSW).Ref_End + winLength;
    case 'ST'
        winLength = floor(1 * handles.Info.Recording.sRate);
        range = handles.SW(nSW).Ref_PeakInd - winLength  :  handles.SW(nSW).Ref_PeakInd + winLength;
end

% check that the range is within data limits (set to sample 1 if not)
range(range < 1 | range > size(Data.Raw, 2)) = 1;
xaxis = range./handles.Info.Recording.sRate;

% Prepare Figure
% ^^^^^^^^^^^^^^
SW_Handles.Figure = figure(...
    'Name',         'Edit Detected Wave',...
    'NumberTitle',  'off',...
    'Color',        'w',...
    'MenuBar',      'none',...
    'Units',        'pixels',...
    'Outerposition',[200 200 900 600]);

SW_Handles.Axes = axes(...
    'Parent',   SW_Handles.Figure,...
    'Position', [0.05 0.05 0.92 0.9],...
    'NextPlot', 'add',...
    'FontName', 'Century Gothic',...
    'FontSize', 8,...
    'box',      'off',...
    'XLim',     [xaxis(1), xaxis(end)],...
    'YDir',     get(handles.axes_individual_wave, 'YDir'));

% Add buttons
% ^^^^^^^^^^^
iconZoom = fullfile(matlabroot,'/toolbox/matlab/icons/tool_zoom_in.png');
iconArrow = fullfile(matlabroot,'/toolbox/matlab/icons/tool_pointer.png'); 
iconTravel = fullfile(matlabroot,'/toolbox/matlab/icons/tool_text_arrow.png'); 

% Just add javacomponent buttons...
[j_pbArrow, SW_Handles.pb_Arrow] = javacomponent(javax.swing.JButton);
set(SW_Handles.pb_Arrow,...
    'Parent',   SW_Handles.Figure,...      
    'Units',    'normalized',...
    'Position', [0.80 0.05 0.05 0.07]);
% >> j_pbZoom.set [then tab complete to find available methods]
j_pbArrow.setIcon(javax.swing.ImageIcon(iconArrow))
set(j_pbArrow, 'ToolTipText', 'Select Channel'); 
set(j_pbArrow, 'MouseReleasedCallback', 'zoom off');

[j_pbZoom, SW_Handles.pb_Zoom] = javacomponent(javax.swing.JButton);
set(SW_Handles.pb_Zoom,...
    'Parent',   SW_Handles.Figure,...      
    'Units',    'normalized',...
    'Position', [0.85 0.05 0.05 0.07]);

j_pbZoom.setIcon(javax.swing.ImageIcon(iconZoom))
set(j_pbZoom, 'ToolTipText', 'Zoom Mode'); 
set(j_pbZoom, 'MouseReleasedCallback', 'zoom on');

[j_pbTravel, SW_Handles.pb_Travel] = javacomponent(javax.swing.JButton);
set(SW_Handles.pb_Travel,...
    'Parent',   SW_Handles.Figure,...      
    'Units',    'normalized',...
    'Position', [0.92 0.05 0.05 0.07]);

j_pbTravel.setIcon(javax.swing.ImageIcon(iconTravel))
set(j_pbTravel, 'ToolTipText', 'Recalculate Travelling'); 
set(j_pbTravel, 'MouseReleasedCallback', {@fcn_UpdateTravelling, handles.fig});

% Plot the data with the reference negative peak centered %

SW_Handles.Plot_Ch = plot(SW_Handles.Axes,...
     xaxis, Data.Raw(:, range)',...
    'Color', [0.8 0.8 0.8],...
    'LineWidth', 0.5,...
    'LineStyle', ':');
set(SW_Handles.Plot_Ch, 'ButtonDownFcn', {@Channel_Selected, handles.fig, SW_Handles});
set(SW_Handles.Plot_Ch(handles.SW(nSW).Channels_Active), 'Color', [0.6 0.6 0.6], 'LineWidth', 1, 'LineStyle', '-');

handles.SWPlot.Ref = plot(SW_Handles.Axes,...
    xaxis, Data.([handles.SW_Type, 'Ref'])(handles.SW(nSW).Ref_Region(1), range)',...
    'Color', 'r',...
    'LineWidth', 3);

if ~strcmp(handles.SW_Type, 'SS') && isfield(Data, 'CWT')
    handles.SWPlot.CWT = plot(SW_Handles.Axes,...
        xaxis, Data.CWT{1}(handles.SW(nSW).Ref_Region(1), range)',...
        'Color', 'b',...
        'LineWidth', 3);
end

function Channel_Selected(hObject, ~ , FigureHandle, SW_Handles)
handles = guidata(FigureHandle);
% a = get(handles.fig, 'SelectionType');

nSW = handles.java.Spinner.getValue();
nCh = find(SW_Handles.Plot_Ch == hObject);

if ~handles.SW(nSW).Channels_Active(nCh)
    handles.SW(nSW).Channels_Active(nCh) = true;
    set(SW_Handles.Plot_Ch(nCh), 'Color', [0.6 0.6 0.6], 'LineWidth', 1, 'LineStyle', '-')
    set(handles.SWPlot.All(nCh), 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'LineStyle', '-', 'Visible', 'on')
else
    handles.SW(nSW).Channels_Active(nCh) = false;
    set(SW_Handles.Plot_Ch(nCh), 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5, 'LineStyle', ':')
    set(handles.SWPlot.All(nCh), 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5, 'LineStyle', '-', 'Visible', 'off')
end

guidata(handles.fig, handles);

function fcn_UpdateTravelling(~, ~ , figure_handle)
% executes on button push in the SW_Plot after manually editing channel
% list

% TODO: change to external function

% get the GUI handles from the original figure
handles = guidata(figure_handle);

% get the data structure
Data = getappdata(handles.fig, 'Data');

% get the current wave number
nSW = handles.java.Spinner.getValue();

% Recalculate the Travelling_Delays parameter before running...
win = round(handles.Info.Parameters.Channels_WinSize ...
    * handles.Info.Recording.sRate);

switch handles.SW_Type
    case 'SW'
        range = handles.SW(nSW).Ref_PeakInd - win * 2 ...
            : handles.SW(nSW).Ref_PeakInd + win * 2;
        ref_range = handles.SW(nSW).Ref_PeakInd - win ...
            : handles.SW(nSW).Ref_PeakInd + win;
    case 'SS'
        range = handles.SW(nSW).Ref_Start - win ...
            : handles.SW(nSW).Ref_End + win;
    case 'ST'
        range = handles.SW(nSW).CWT_NegativePeak - win ...
            : handles.SW(nSW).CWT_NegativePeak + win;
end

% extract data
current_data    = Data.Raw(handles.SW(nSW).Channels_Active, range);

% recalculate the wavelets for SS and ST
switch handles.SW_Type
    case 'SS'
        % get the scale range corresponding to the frequencies of interest
        FreqRange   = handles.Info.Parameters.Filter_hPass(1) : handles.Info.Parameters.Filter_lPass(end);
        scale       = (centfrq('morl')./ FreqRange) * handles.Info.Recording.sRate;
        
        cwtData = zeros(size(current_data));
        for n = 1:size(current_data,1)
            cwtData(n,:) = mean(cwt(current_data(n , : ), scale, 'morl' ));
        end
        
    case 'ST'
        
         % get the scale range corresponding to the frequencies of interest
        FreqRange   = handles.Info.Parameters.CWT_hPass(1) : handles.Info.Parameters.CWT_lPass(end);
        scale       = (centfrq('morl')./ FreqRange) * handles.Info.Recording.sRate;
        
        cwtData = zeros(size(current_data));
        for n = 1:size(current_data,1)
            cwtData(n,:) = mean(cwt(current_data(n , : ), scale, 'morl' ));
        end
end

% Recalculate the delays and peak2peak amplitudes differently for each type
switch handles.SW_Type
    case 'SW'
        
        % get the reference data for comparison        
        reference_data     = mean(Data.SWRef(handles.SW(nSW).Ref_Region, ref_range), 1);
        
        % perform cross-correlation again
        cc = swa_xcorr(reference_data, current_data, win);
        
        % find the maximum correlation and location
        [~, max_ind]      = max(cc, [], 2);
        
        % only take delays for active channels
        handles.SW(nSW).Travelling_Delays = nan(length(handles.Info.Electrodes), 1);
        handles.SW(nSW).Travelling_Delays(handles.SW(nSW).Channels_Active)...
            = max_ind - min(max_ind);
        
        % eliminate the old delay map
        handles.SW(nSW).Travelling_DelayMap = [];
        handles.SW(nSW).Travelling_Streams = [];
        
        % travelling calculation for only the current wave        
        [handles.Info, handles.SW] = swa_FindSTTravelling(handles.Info, handles.SW, nSW);
        
    case 'SS'
        % calculate the power of each cwt
        % filter window
        powerWindow = ones((handles.Info.Parameters.Filter_Window * handles.Info.Recording.sRate), 1) /...
            (handles.Info.Parameters.Filter_Window * handles.Info.Recording.sRate);
        powerData = cwtData.^2;
        powerData = filter(powerWindow, 1, powerData')';
        
        % find the time of the peak of the powerData (shortPower)
        [~, max_ind] = max(powerData, [], 2);
        
        % Find delays based on time of maximum power
        handles.SW(nSW).Travelling_Delays = nan(length(handles.Info.Electrodes), 1);
        handles.SW(nSW).Travelling_Delays(handles.SW(nSW).Channels_Active) = max_ind - min(max_ind);
        
        % calculate new peak2peaks
        slope_data  = diff(current_data, 1, 2);
               
        % -- Find all the peaks, both positive and negative -- %
        peak2peak = nan(sum(handles.SW(nSW).Channels_Active), 1);
        channel_indices = find(handles.SW(nSW).Channels_Active);
        for ch = 1 : size(slope_data, 1)
            % peak indices for that channel
            peak_indices = find(abs(diff(sign(slope_data(ch, :)), 1, 2)));
            
            % get the largest amplitude
            peakAmp = Data.Raw(channel_indices(ch),...
                handles.SW(nSW).Ref_Start + peak_indices);
            
            % if a channel has less than 3 peaks, delete it
            if length(peakAmp) < 3
                peak2peak(ch, :) = nan;
                handles.SW(nSW).Channels_Active(channel_indices(ch)) = false;
                continue;
            end
            peak2peak(ch, :) = max(abs(diff(peakAmp)));
        end
        
        % put the peaks back into the SS structure
        handles.SW(nSW).Channels_Power = nan(length(handles.Info.Electrodes),1);
        handles.SW(nSW).Channels_Power(handles.SW(nSW).Channels_Active) = peak2peak;
        
    case 'ST'
        % TODO: peak2peak amplitude adjustment for ST
        [~, Ch_Id] = min(cwtData, [], 2);
        
        handles.SW(nSW).Travelling_Delays = nan(size(Data.Raw,1),1);
        handles.SW(nSW).Travelling_Delays(handles.SW(nSW).Channels_Active) = Ch_Id - min(Ch_Id);
        
        % remove old streams
        handles.SW(nSW).Travelling_Streams = [];
        [handles.Info, handles.SW] = swa_FindSTTravelling(handles.Info, handles.SW, nSW);
end

handles = update_SWDelay(handles, 0);
guidata(handles.fig, handles);

function fcn_context_axes_channel(hObject, ~, Direction)
handles = guidata(hObject);
set(handles.axes_eeg_channel,   'YDir', Direction)
set(handles.axes_individual_wave,      'YDir', Direction)

function btf_add_wave(hObject, event_data)
% check which button was pushed
if event_data.Button ~= 1
    return;
end

% get the handles structure
handles = guidata(hObject);

% only available for SW
if ~strcmp(handles.SW_Type, {'SW', 'ST'})
    fprintf(1, 'Manual wave additions only available for slow waves.\n');
    return;    
end

% get the data structure
Data = getappdata(handles.fig, 'Data');

% calculate the sampling point from the time
sample_point = round(event_data.IntersectionPoint(1) * handles.Info.Recording.sRate);

% add the new wave and calculate its properties
[handles.SW, new_ind] = swa_manual_addition(...
    Data, handles.Info, handles.SW, sample_point, handles.SW_Type);

if isempty(new_ind)
    return;
end

% reset the maximum of the slider
handles.java.Slider.setMaximum(length(handles.SW));

% delete the arrow on the butterfly plot then the handle
arrow_position = handles.arrows_Butterfly(1).Position(2);
delete(handles.arrows_Butterfly);
handles.arrows_Butterfly = [];

% Just plot all the arrows already
wave_peaks = [handles.SW.Ref_PeakInd]./ handles.Info.Recording.sRate;
handles.arrows_Butterfly = text(wave_peaks, ones(1, length(wave_peaks)) * arrow_position,...
    '\downarrow',...
    'fontSize', 20 ,...
    'horizontalAlignment', 'center' ,...
    'clipping', 'on',...
    'parent', handles.axes_eeg_channel(1));

% update the handles structure
guidata(handles.fig, handles);

% check the current wave in case wave was added before
nSW = handles.java.Spinner.getValue();
if nSW == new_ind
    handles.java.Spinner.setValue(nSW + 1);
end

% set the slider to the newly added wave
% handles.java.Spinner.setValue(new_ind);


% Big plot check-box callback
function UpdateDelay2(hObject, ~)
handles = guidata(hObject);
update_SWDelay(handles, 0);
