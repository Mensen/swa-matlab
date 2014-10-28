%% GUI for Exploring Travelling Waves
function swa_Explorer(varargin)
DefineInterface

function DefineInterface
%% Create Figure

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

%% Menus
handles.menu.File = uimenu(handles.fig, 'Label', 'File');
handles.menu.LoadData = uimenu(handles.menu.File,...
    'Label', 'Load Data',...
    'Accelerator', 'L');
set(handles.menu.LoadData, 'Callback', {@menu_LoadData});

handles.menu.SaveData = uimenu(handles.menu.File,...
    'Label', 'Save Data',...
    'Accelerator', 'S');
set(handles.menu.SaveData, 'Callback', {@menu_SaveData});

%% Status Bar
handles.StatusBar = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'text',...    
    'String',   'Status Updates',...
    'Units',    'normalized',...
    'Position', [0 0 1 0.03],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);

handles.java.StatusBar = findjobj(handles.StatusBar); 

% first java call may cause 'no appropriate method' error 
% as handle is not visible
drawnow; pause(0.1);

% set the alignment of the status bar
handles.java.StatusBar.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
handles.java.StatusBar.setHorizontalAlignment(javax.swing.SwingConstants.LEFT);

%% Slider Spinner and Delete Button
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

%% Channel Set ComboBoxes
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

%% Plot Titles and Export Button
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
    'Style',    'text',...    
    'Units',    'normalized',...
    'Position', [0.5 .73 0.45 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
[handles.java.PlotBox,handles.PlotBox] = javacomponent(javax.swing.JComboBox);
set(handles.PlotBox,...
    'Parent',   handles.fig,...      
    'Units',    'normalized',...
    'Position', [0.65 0.73 0.15 0.02]);
handles.java.PlotBox.setModel(javax.swing.DefaultComboBoxModel({'Delay Map', 'Involvement Map'}));
handles.java.PlotBox.setFont(javax.swing.plaf.FontUIResource('Century Gothic', 0, 14));
set(handles.java.PlotBox, 'ActionPerformedCallback', {@SliderUpdate, handles.fig});

handles.Ex_Delay = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'pushbutton',...    
    'String',   '+',...
    'Units',    'normalized',...
    'Position', [0.93 .73 0.02 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
set(handles.Ex_Delay, 'Callback', @pb_XDelay_Callback)

%% Checkboxes for Delay
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
handles.theta_Cb = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'checkbox',...
    'BackgroundColor', 'w',...
    'String',   '<html>&#952</html>',...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.05 .4 0.02 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
% set(handles.Surface_Delay, 'Callback', @UpdateDelay2);

handles.alpha_Cb = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'checkbox',...
    'BackgroundColor', 'w',...
    'String',   '<html>&#945</html>',...
    'Value',    1,...
    'Units',    'normalized',...
    'Position', [0.07 .4 0.02 0.02],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);

%% Create Axes
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

%% Two Wave Summary Plots
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

% get the currently available options
options_list = swa_wave_summary('return options');

% create and set the java models for the options list
model1 = javax.swing.DefaultComboBoxModel(options_list);
model2 = javax.swing.DefaultComboBoxModel(options_list);
handles.java.options_list(1).setModel(model1);
handles.java.options_list(2).setModel(model2);

% set the second option box to the second value (0-index value 1)
handles.java.options_list(2).setSelectedIndex(1)

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

%% Context Menus
handles.menu.ButterflyContext = uicontextmenu;
handles.menu.UIContext_YReverse = uimenu(handles.menu.ButterflyContext,...
    'Label',    'Negative Down',...
    'Callback', {@fcn_context_axes_channel, 'normal'});
handles.menu.UIContext_YReverse = uimenu(handles.menu.ButterflyContext,...
    'Label',    'Negative Up',...
    'Callback', {@fcn_context_axes_channel, 'reverse'});
set(handles.axes_eeg_channel, 'uicontextmenu', handles.menu.ButterflyContext);
set(handles.axes_individual_wave, 'uicontextmenu', handles.menu.ButterflyContext);

%% Make Figure Visible and Maximise
jFrame = get(handle(handles.fig),'JavaFrame');
jFrame.setMaximized(true);   % to maximize the figure

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
    set(handles.StatusBar, 'String', 'Busy: Loading Data');
    fid = fopen(fullfile(swaPath, loaded_file.Data.Raw));
    loaded_file.Data.Raw = fread(fid, loaded_file.Info.Recording.dataDim, 'single');
    fclose(fid);
end

% Set each handle type separately
if isfield(loaded_file, 'SW')
    handles.SW = loaded_file.SW;
    handles.SW_Type = 'SW';
elseif isfield(loaded_file, 'ST')
    handles.SW = loaded_file.ST;
    handles.SW_Type = 'ST';
elseif isfield(loaded_file, 'SS')
    handles.SW = loaded_file.SS;
    handles.SW_Type = 'SS';
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

%% Draw Initial Plots
% Update handles structure
guidata(handles.fig, handles);
setappdata(handles.fig, 'Data', loaded_file.Data);

% Two summary plots
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
save([savePath, saveName], 'Data', 'Info', handles.SW_Type, '-mat');

set(handles.fig, 'Name', ['Travelling Waves: ', saveName]);


%% Update Controls
function SpinnerUpdate(~,~,hObject)
handles = guidata(hObject); % Needs to be like this because slider is a java object

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


%% Plot Controls
function handles = update_axes_channels(handles)

% get the data structure
Data = getappdata(handles.fig, 'Data');

% get current wave
nSW = handles.java.Spinner.getValue();

% Calculate the range
if strcmp(handles.SW_Type, 'SS')
    winLength = floor((30*handles.Info.sRate - handles.SW(nSW).Ref_Length)/2);
    range = handles.SW(nSW).Ref_Start - winLength  :  handles.SW(nSW).Ref_End + winLength;
else
    winLength = floor(10*handles.Info.Recording.sRate);
    range = handles.SW(nSW).Ref_PeakInd - winLength  :  handles.SW(nSW).Ref_PeakInd + winLength;
end
range(range<1) = [];
xaxis = range./handles.Info.Recording.sRate;

if strcmp(handles.SW_Type, 'SS')
    sPeaks = [handles.SW.Ref_Start]+[handles.SW.Ref_Length]./2./handles.Info.sRate;
else
    sPeaks = [handles.SW.Ref_PeakInd]./handles.Info.Recording.sRate;
end

% check for special selected channels
for n = 1:2
    selected_label = handles.java.ChannelBox(n).getSelectedItem;
    
    if strcmp(selected_label, 'All')
        data_to_plot{n} = Data.Raw(:, range);
    elseif strcmp(selected_label, 'Ref')
        data_to_plot{n} = Data.SWRef(:, range);
    else
        Ch = handles.java.ChannelBox(n).getSelectedIndex()+1;
        data_to_plot{n} = Data.Raw(Ch, range);
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
        rmfield(handles, 'lines_eeg_channel');
        plot_method = 'initial';
    end  
end

switch plot_method
    case 'initial'
        % initial Plot (50 times takes 1.67s)
        
        handles.lines_eeg_channel{1} = plot(handles.axes_eeg_channel(1), xaxis, data_to_plot{1}', 'k');
        handles.lines_eeg_channel{2} = plot(handles.axes_eeg_channel(2), xaxis, data_to_plot{2}', 'k');
        
        set(handles.axes_eeg_channel,...
            'YLim', [-70,70],...
            'XLim', [xaxis(1), xaxis(end)]);
        
        if strcmp(handles.SW_Type, 'SS')
            handles.zoomline(1) = line([handles.SW(nSW).Ref_Start/handles.Info.sRate-0.5,   handles.SW(nSW).Ref_Start/handles.Info.sRate-0.5],[-200, 200], 'color', [0.4 0.4 0.4], 'linewidth', 2, 'Parent', handles.axes_eeg_channel(1));
            handles.zoomline(2) = line([handles.SW(nSW).Ref_End/handles.Info.sRate+.5,      handles.SW(nSW).Ref_End/handles.Info.sRate+0.5],[-200, 200], 'color', [0.4 0.4 0.4], 'linewidth', 2, 'Parent', handles.axes_eeg_channel(1));
        else
            handles.zoomline(1) = line([handles.SW(nSW).Ref_PeakInd/handles.Info.Recording.sRate-0.5, handles.SW(nSW).Ref_PeakInd/handles.Info.Recording.sRate-0.5],[-200, 200], 'color', [0.4 0.4 0.4], 'linewidth', 2, 'Parent', handles.axes_eeg_channel(1));
            handles.zoomline(2) = line([handles.SW(nSW).Ref_PeakInd/handles.Info.Recording.sRate+.5, handles.SW(nSW).Ref_PeakInd/handles.Info.Recording.sRate+0.5],[-200, 200], 'color', [0.4 0.4 0.4], 'linewidth', 2, 'Parent', handles.axes_eeg_channel(1));
        end
        
        % Just plot all the arrows already
        handles.arrows_Butterfly = text(sPeaks, ones(1, length(sPeaks))*30, '\downarrow', 'FontSize', 20, 'HorizontalAlignment', 'center', 'Clipping', 'on', 'Parent', handles.axes_eeg_channel(1));
        
        % Re-plotting (50 times takes 0.3s)
    case 'replot'
        % loop each axes
        for a = 1:2
            set(handles.lines_eeg_channel{a}, 'xData', xaxis);
            
            % loop for each channel (only more than 1 for All or Ref)
            for n = 1:size(data_to_plot{a}, 1)
                set(handles.lines_eeg_channel{a}(n), 'yData', data_to_plot{a}(n,:)');
            end
        end
        
        set(handles.axes_eeg_channel,...
            'XLim', [xaxis(1), xaxis(end)]);
        
        set(handles.zoomline(1), 'xData', [handles.SW(nSW).Ref_DownInd/handles.Info.Recording.sRate-0.5,    handles.SW(nSW).Ref_DownInd/handles.Info.Recording.sRate-0.5]);
        set(handles.zoomline(2), 'xData', [handles.SW(nSW).Ref_UpInd/handles.Info.Recording.sRate+0.5,      handles.SW(nSW).Ref_UpInd/handles.Info.Recording.sRate+0.5]);
end

function handles = update_SWPlot(handles)

% get the data structure
Data = getappdata(handles.fig, 'Data');

% get the current wave number
nSW = handles.java.Spinner.getValue();

% Calculate the range
if strcmp(handles.SW_Type, 'SS')
    winLength = floor((2*handles.Info.sRate - handles.SW(nSW).Ref_Length)/2);
    range = handles.SW(nSW).Ref_Start - winLength  :  handles.SW(nSW).Ref_End + winLength;
else
    winLength = floor(2*handles.Info.Recording.sRate);
    range = handles.SW(nSW).Ref_PeakInd - winLength  :  handles.SW(nSW).Ref_PeakInd + winLength;
end
range(range<1) = [];

% check if the plot already exist (if not then initialise, else change
% ydata)
if ~isfield(handles, 'SWPlot') % in case plot doesn't already exist
    cla(handles.axes_individual_wave);
    
    % plot all the channels but hide them
    handles.SWPlot.All      = plot(handles.axes_individual_wave, Data.Raw(:, range)', 'Color', [0.6 0.6 0.6], 'linewidth', 0.5, 'Visible', 'off');
    % plot the reference wave
    handles.SWPlot.Ref      = plot(handles.axes_individual_wave, Data.([handles.SW_Type, 'Ref'])(handles.SW(nSW).Ref_Region(1), range)','Color', 'r', 'linewidth', 3);
    % plot wavelets
    if isfield(Data, 'CWT')
        for np = 1:length(Data.CWT)
            handles.SWPlot.CWT(np)   = plot(handles.axes_individual_wave, Data.CWT{np}(handles.SW(nSW).Ref_Region(1),range)','Color', 'b', 'linewidth', 2);
        end
    end
    
    % set only the active channels to visible
    set(handles.SWPlot.All(handles.SW(nSW).Channels_Active), 'Color', [0.6 0.6 0.6], 'LineWidth', 1, 'Visible', 'on');
    set(handles.axes_individual_wave, 'XLim', [1, length(range)])
    
else
    for i = 1:size(Data.Raw,1) % faster than total replot...
        set(handles.SWPlot.All(i),...
            'yData', Data.Raw(i,range),...
            'Color', [0.6 0.6 0.6], 'linewidth', 0.5, 'Visible', 'off');
    end
    set(handles.SWPlot.All(handles.SW(nSW).Channels_Active), 'Color', [0.6 0.6 0.6], 'LineWidth', 1, 'Visible', 'on');
    %     set(handles.SWPlot.All(handles.SW(nSW).Travelling_Delays<1), 'Color', 'b', 'LineWidth', 2, 'Visible', 'on');
    
    set(handles.SWPlot.Ref, 'yData', Data.([handles.SW_Type, 'Ref'])(handles.SW(nSW).Ref_Region(1),range));
    
    set(handles.SWPlot.Ref, 'yData', Data.([handles.SW_Type, 'Ref'])(handles.SW(nSW).Ref_Region(1),range));
    
    % Find the absolute maximum value and round to higher 10, then add 10 for space
    dataMax = ceil(abs(max(max(Data.Raw(handles.SW(nSW).Channels_Active, range))))/10)*10+10;
    set(handles.axes_individual_wave, 'YLim', [-dataMax, dataMax])
    
    % Plot the cwt data...
    if isfield(Data, 'CWT')
        for np = 1:length(Data.CWT)
            % if its spindle power plot below line
            if strcmp(handles.SW_Type, 'SS')
                data = Data.CWT{np}(handles.SW(nSW).Ref_Region(1),range);
                set(handles.SWPlot.CWT(1), 'yData', (data./max(data)*dataMax) - dataMax);
            else
                set(handles.SWPlot.CWT(1), 'yData', Data.CWT{np}(handles.SW(nSW).Ref_Region(1),range));
            end
        end
    end

%     % Check theta and alpha checkboxes
%     if get(handles.theta_Cb, 'value')
%         set(handles.SWPlot.CWT(1), 'yData', Data.CWT{1}(handles.SW(nSW).Ref_Region(1),range));
%     else
%         set(handles.SWPlot.CWT(1), 'yData', []);       
%     end
%     if get(handles.alpha_Cb, 'value')
%         set(handles.SWPlot.CWT(2), 'yData', Data.CWT{2}(handles.SW(nSW).Ref_Region(1),range));
%     else
%         set(handles.SWPlot.CWT(2), 'yData', []);             
%     end

end

function handles = update_SWDelay(handles, nFigure)
% plot the delay/involvement map

% get the current wave number
nSW = handles.java.Spinner.getValue();

% clear the axes for a new plot
if nFigure ~= 1; 
    cla(handles.ax_Delay); 
end

% plot the Delay Map...
if handles.java.PlotBox.getSelectedIndex()+1 == 1

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
elseif handles.java.PlotBox.getSelectedIndex()+1 == 2;   
    
    swa_Topoplot...
        ([],                handles.Info.Electrodes             ,...
        'Data',             handles.SW(nSW).Channels_NegAmp     ,...
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
cla(handles.ax_option(no_axes));

% get the selected option
type = handles.java.options_list(no_axes).getSelectedItem;

% draw the selected summary statistic on the axes
swa_wave_summary(handles.SW, handles.Info,...
    type, 1, handles.ax_option(no_axes));


%% Push Buttons

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



%% Manually Edit Waves
function edit_SWPlot(hObject, ~)
handles = guidata(hObject);

% get the data structure
Data = getappdata(handles.fig, 'Data');

% get the current wave number
nSW = handles.java.Spinner.getValue();

% Calculate the range
if strcmp(handles.SW_Type, 'SS')
    winLength = floor((2*handles.Info.sRate - handles.SW(nSW).Ref_Length)/2);
    range = handles.SW(nSW).Ref_Start - winLength  :  handles.SW(nSW).Ref_End + winLength;
else
    winLength = floor(2*handles.Info.Recording.sRate);
    range = handles.SW(nSW).Ref_PeakInd - winLength  :  handles.SW(nSW).Ref_PeakInd + winLength;
end
range(range<1) = [];
xaxis = range./handles.Info.Recording.sRate;

%% Prepare Figure
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

%% Add buttons
iconZoom = fullfile(matlabroot,'/toolbox/matlab/icons/tool_zoom_in.png');
iconArrow = fullfile(matlabroot,'/toolbox/matlab/icons/tool_pointer.png'); 
iconTravel = fullfile(matlabroot,'/toolbox/matlab/icons/tool_text_arrow.png'); 

% Just add javacomponent buttons...
[j_pbArrow,SW_Handles.pb_Arrow] = javacomponent(javax.swing.JButton);
set(SW_Handles.pb_Arrow,...
    'Parent',   SW_Handles.Figure,...      
    'Units',    'normalized',...
    'Position', [0.80 0.05 0.05 0.07]);
% >> j_pbZoom.set [then tab complete to find available methods]
j_pbArrow.setIcon(javax.swing.ImageIcon(iconArrow))
set(j_pbArrow, 'ToolTipText', 'Select Channel'); 
set(j_pbArrow, 'MouseReleasedCallback', 'zoom off');

[j_pbZoom,SW_Handles.pb_Zoom] = javacomponent(javax.swing.JButton);
set(SW_Handles.pb_Zoom,...
    'Parent',   SW_Handles.Figure,...      
    'Units',    'normalized',...
    'Position', [0.85 0.05 0.05 0.07]);
% >> j_pbZoom.set [then tab complete to find available methods]
j_pbZoom.setIcon(javax.swing.ImageIcon(iconZoom))
set(j_pbZoom, 'ToolTipText', 'Zoom Mode'); 
set(j_pbZoom, 'MouseReleasedCallback', 'zoom on');

[j_pbTravel,SW_Handles.pb_Travel] = javacomponent(javax.swing.JButton);
set(SW_Handles.pb_Travel,...
    'Parent',   SW_Handles.Figure,...      
    'Units',    'normalized',...
    'Position', [0.92 0.05 0.05 0.07]);
% >> j_pbZoom.set [then tab complete to find available methods]
j_pbTravel.setIcon(javax.swing.ImageIcon(iconTravel))
set(j_pbTravel, 'ToolTipText', 'Recalculate Travelling'); 
set(j_pbTravel, 'MouseReleasedCallback', {@fcn_UpdateTravelling, handles.fig});

%% Plot the data with the reference negative peak centered %
SW_Handles.Plot_Ch = plot(SW_Handles.Axes,...
     xaxis, Data.Raw(:,range)',...
    'Color', [0.8 0.8 0.8],...
    'LineWidth', 0.5,...
    'LineStyle', ':');
set(SW_Handles.Plot_Ch, 'ButtonDownFcn', {@Channel_Selected, handles.fig, SW_Handles});
set(SW_Handles.Plot_Ch(handles.SW(nSW).Channels_Active), 'Color', [0.6 0.6 0.6], 'LineWidth', 1, 'LineStyle', '-');
% set(SW_Handles.Plot_Ch(handles.SW(nSW).Travelling_Delays<1), 'Color', 'b', 'LineWidth', 2, 'LineStyle', '-');

handles.SWPlot.Ref = plot(SW_Handles.Axes,...
    xaxis, Data.([handles.SW_Type, 'Ref'])(handles.SW(nSW).Ref_Region(1),range)',...
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

function fcn_UpdateTravelling(~, ~ , FigureHandle)
% executes on button push in the SW_Plot after manually editing channel
% list

% TODO: change to external function
% TODO: make it work for SW (problem since currently looking for wavelet data)

% get the GUI handles from the original figure
handles = guidata(FigureHandle);

% get the data structure
Data = getappdata(handles.fig, 'Data');

% get the current wave number
nSW = handles.java.Spinner.getValue();

% Recalculate the Travelling_Delays parameter before running...
win = round(handles.Info.Parameters.Channels_WinSize*handles.Info.Recording.sRate);

switch handles.SW_Type
    case 'SW'
        range = handles.SW(nSW).Ref_PeakInd-win:handles.SW(nSW).Ref_PeakInd+win;       
    case 'SS'
        range = handles.SW(nSW).Ref_Start-win:handles.SW(nSW).Ref_End+win;
    case 'ST'
        range = handles.SW(nSW).CWT_NegativePeak-win:handles.SW(nSW).CWT_NegativePeak+win;
end

currData    = Data.Raw(handles.SW(nSW).Channels_Active, range);

FreqRange   = handles.Info.Parameters.CWT_hPass:handles.Info.Parameters.CWT_lPass;
scale       = (centfrq('morl')./FreqRange)*handles.Info.sRate;

cwtData= zeros(size(currData));
for i = 1:size(currData,1)
    cwtData(i,:) = mean(cwt(currData(i,:),scale,'morl'));
end

% Recalculate the delays and peak2peak amplitudes differently for each type
if strcmp(handles.SW_Type, 'SS')
    % calculate the power of each cwt
    powerWindow = ones((handles.Info.sRate/10),1)/(handles.Info.sRate/10); % create 100ms window to convolve with
    powerData = cwtData.^2;
    powerData = filter(powerWindow,1,powerData')';
    
    % find the time of the peak of the powerData (shortPower)
    [~, maxID] = max(powerData,[],2);     
    
    % Find delays based on time of maximum power
    handles.SW(nSW).Travelling_Delays = nan(length(handles.Info.Electrodes),1);
    handles.SW(nSW).Travelling_Delays(handles.SW(nSW).Channels_Active) = maxID - min(maxID);
      
    % calculate new peak2peaks
    slopeData  = diff(currData, 1, 2);
        
    peak2Peak = nan(sum(handles.SW(nSW).Channels_Active),1);  
    % Find all the peaks, both positive and negative
    for ch = 1:size(slopeData, 1)
        % Find all the peaks, both positive and negative
        peakAmp = currData(ch, find(abs(diff(sign(slopeData(ch,:)), 1, 2)== 2)));
        % if a channel has less than 3 peaks, delete it
        if length(peakAmp) < 2
            peak2Peak(ch,:) = nan;
            continue;
        end
        peak2Peak(ch,:)   = max(abs(diff(peakAmp)));
    end
    
    handles.SW(nSW).Channels_Peak2PeakAmp = nan(length(handles.Info.Electrodes),1);
    handles.SW(nSW).Channels_Peak2PeakAmp(handles.SW(nSW).Channels_Active) = peak2Peak;
    
else
    % to do: peak2peak amplitude adjustment for ST
    [~, Ch_Id] = min(cwtData, [],2);
    
    handles.SW(nSW).Travelling_Delays = nan(size(Data.Raw,1),1);
    handles.SW(nSW).Travelling_Delays(handles.SW(nSW).Channels_Active) = Ch_Id-min(Ch_Id);
    
    [handles.Info, handles.SW] = swa_FindSTTravelling(handles.Info, handles.SW, nSW);
end

handles = update_SWDelay(handles, 0);
guidata(handles.fig, handles);

function fcn_context_axes_channel(hObject, ~, Direction)
handles = guidata(hObject);
set(handles.axes_eeg_channel,   'YDir', Direction)
set(handles.axes_individual_wave,      'YDir', Direction)


%% Big plot check-box callback
function UpdateDelay2(hObject, ~)
handles = guidata(hObject);
update_SWDelay(handles, 0);
