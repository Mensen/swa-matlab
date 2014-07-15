%% -- Manual Sleep Scoring GUI -- %%
function swa_SleepScoring(varargin)
% GUI to quickly score sleep stages and save the results for further
% processing (e.g. travelling waves analysis)

% Author: Armand Mensen

% Version 1.0

DefineInterface

function DefineInterface
handles.Figure = figure(...
    'Name',         'Sleep Scoring',...
    'NumberTitle',  'off',...
    'Color',        'w',...
    'MenuBar',      'none',...
    'Units',        'normalized',...
    'Outerposition',[0 0.04 .5 0.96]);

%% Menus
handles.menu.File = uimenu(handles.Figure, 'Label', 'File');
handles.menu.LoadEEG = uimenu(handles.menu.File,...
    'Label', 'Load EEG',...
    'Accelerator', 'L');
handles.menu.SaveEEG = uimenu(handles.menu.File,...
    'Label', 'Save EEG',...
    'Accelerator', 'S');
handles.menu.LoadMontage = uimenu(handles.menu.File,...
    'Label', 'Load Montage',...
    'Separator', 'on');

handles.menu.Tools      = uimenu(handles.Figure, 'Label', 'Tools', 'Enable', 'off');
handles.menu.Filter     = uimenu(handles.menu.Tools,'Label', 'Filter');
handles.menu.Reference  = uimenu(handles.menu.Tools,'Label', 'Reference');

handles.menu.Export = uimenu(handles.Figure, 'Label', 'Export', 'Enable', 'off');
handles.menu.N2  = uimenu(handles.menu.Export,'Label', 'N2');
handles.menu.N3  = uimenu(handles.menu.Export,'Label', 'N3');
handles.menu.REM = uimenu(handles.menu.Export,'Label', 'REM');

handles.menu.Statistics = uimenu(handles.Figure, 'Label', 'Statistics', 'Enable', 'off');
% can use html labels here to alter fonts

%% Status Bar
handles.StatusBar = uicontrol(...
    'Parent',   handles.Figure,...   
    'Style',    'text',...    
    'String',   'Status Updates',...
    'Units',    'normalized',...
    'Position', [0 0 1 0.03],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);

jandles.StatusBar = findjobj(handles.StatusBar);
jandles.StatusBar.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
jandles.StatusBar.setHorizontalAlignment(javax.swing.SwingConstants.LEFT);

%% Slider
% handles.sl_Epochs = uicontrol(...
%     'Style',    'slider',...    
%     'Backgroundcolor', 'w',...
%     'Units',    'normalized',...
%     'Position', [0.15 0.25 0.75 0.025]);
[handles.java.Slider, handles.sl_Epochs] = javacomponent(javax.swing.JSlider);
handles.java.Slider.setBackground(javax.swing.plaf.ColorUIResource(1,1,1))
set(handles.sl_Epochs,...
    'Parent',   handles.Figure,...      
    'Units',    'normalized',...
    'Position', [0.147 0.23 0.756 0.05]);
set(handles.java.Slider, 'MouseReleasedCallback',{@sliderUpdate, handles.Figure});
  
%% Create PopUpMenus and Axes
for i = 1:8
	handles.axCh(i) = axes(...
        'Parent', handles.Figure,...
        'Position', [0.15 (9-i)*0.08+0.225 0.75 0.08],...
        'NextPlot', 'add',...
        'drawmode', 'fast',...
        'FontName', 'Century Gothic',...
        'FontSize', 8);
	handles.pmCh(i) = uicontrol(...
        'Parent',   handles.Figure,...  
        'Style',    'popupmenu',...  
        'BackgroundColor', 'w',...
        'Units',    'normalized',...
        'Position', [0.11 (9-i)*0.08+0.232 0.04 0.04],...
        'String',   ['Channel ', num2str(i)],...
        'UserData',  i,...
        'FontName', 'Century Gothic',...
        'FontSize', 8);
end

set(handles.axCh(1:end-1),...
    'box', 'off',...
    'Xtick', [],...
    'Ytick', []);

% use the third axes to mark arousals
set(handles.axCh(3), 'buttondownfcn', {@fcn_select_events, handles.axCh(3), 'buttondown'})

%% Scoring Buttons

handles.bg_Scoring = uibuttongroup(...
    'Title','Stage',...
    'FontName', 'Century Gothic',...
    'FontSize', 11,...
    'FontWeight', 'bold',...
    'BackgroundColor', 'w',...
    'Position',[0.92 0.375 0.05 0.5]);
% Create radio buttons in the button group.
handles.rb(1) = uicontrol('Style','radiobutton','String','Wake','UserData', 0,...
    'Units', 'normalized', 'Position',[0.1 9/12 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(2) = uicontrol('Style','radiobutton','String','N1','UserData', 1,...
    'Units', 'normalized', 'Position',[0.1 7/12 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(3) = uicontrol('Style','radiobutton','String','N2','UserData', 2,...
    'Units', 'normalized', 'Position',[0.1 5/12 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(4) = uicontrol('Style','radiobutton','String','N3','UserData', 3,...
    'Units', 'normalized', 'Position',[0.1 3/12 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(5) = uicontrol('Style','radiobutton','String','REM','UserData', 5,...
    'Units', 'normalized', 'Position',[0.1 1/12 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');

set(handles.bg_Scoring,'SelectedObject',[]);  % No selection
set(handles.rb, 'BackgroundColor', 'w', 'FontName', 'Century Gothic','FontSize', 10);

%% Create StageBar

handles.StageBar = uicontrol(...
    'Parent', handles.Figure,...    
    'Style',    'text',...    
    'String',   '1: Unscored',...
    'ForegroundColor', 'k',...
    'Units',    'normalized',...
    'Position', [0.15 0.935 0.75 0.02],...
    'FontName', 'Century Gothic',...
    'FontWeight', 'bold',...   
    'FontSize', 10);

%% Create Hyponogram
handles.axHypno = axes(...
    'Parent', handles.Figure,...
    'Position', [0.15 0.050 0.75 0.15],...
    'YLim',     [0 5.9],...
    'YDir',     'reverse',...
    'NextPlot', 'add',...
    'FontName', 'Century Gothic',...
    'FontSize', 8);

%% Epoch Length
handles.tx_EpochLength = uicontrol(...
    'Parent',   handles.Figure,...   
    'Style',    'text',...    
    'String',   'Epoch Length(s)',...
    'Units',    'normalized',...
    'Position', [0.025 0.85 0.05 0.035],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);
handles.et_EpochLength = uicontrol(...
    'Parent',   handles.Figure,...   
    'Style',    'edit',...    
    'BackgroundColor', 'w',...
    'String',   '30',...
    'Units',    'normalized',...
    'Position', [0.025 0.815 0.05 0.035],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);

%% Scale
handles.tx_Scale = uicontrol(...
    'Parent',   handles.Figure,...   
    'Style',    'text',...    
    'String',   'Scale (microvolts)',...
    'Units',    'normalized',...
    'Position', [0.025 0.65 0.05 0.035],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);
handles.et_Scale = uicontrol(...
    'Parent',   handles.Figure,...   
    'Style',    'edit',...    
    'BackgroundColor', 'w',...
    'String',   '200',...
    'Units',    'normalized',...
    'Position', [0.025 0.615 0.05 0.035],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);

%% Filter Boxes
handles.tx_Filter = uicontrol(...
    'Parent',   handles.Figure,...   
    'Style',    'text',...    
    'String',   'Filter Parameters',...
    'Units',    'normalized',...
    'Position', [0.025 0.45 0.05 0.035],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);
handles.et_HighPass = uicontrol(...
    'Parent',   handles.Figure,...   
    'Style',    'edit',...    
    'BackgroundColor', 'w',...
    'String',   '0.5',...
    'Units',    'normalized',...
    'Position', [0.025 0.415 0.025 0.035],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);
handles.et_LowPass= uicontrol(...
    'Parent',   handles.Figure,...   
    'Style',    'edit',...    
    'BackgroundColor', 'w',...
    'String',   '30',...
    'Units',    'normalized',...
    'Position', [0.05 0.415 0.025 0.035],...
    'FontName', 'Century Gothic',...
    'FontSize', 10);

%% Set Callbacks
set(handles.menu.LoadEEG,...
    'Callback', {@menu_LoadEEG, handles});
set(handles.menu.SaveEEG,...
    'Callback', {@menu_SaveEEG});
set(handles.menu.LoadMontage,...
    'Callback', {@menu_LoadMontage});

set(handles.menu.Filter,...
    'Callback', {@menu_Filter});

set(handles.menu.N2,...
    'Callback', {@menu_Export, 2});
set(handles.menu.N3,...
    'Callback', {@menu_Export, 3});
set(handles.menu.REM,...
    'Callback', {@menu_Export, 5});

set(handles.et_HighPass,...
    'Callback', {@CheckFilter, 1});
set(handles.et_LowPass,...
    'Callback', {@CheckFilter, 2});

set(handles.pmCh,...
    'Callback', {@ChangeChannel});

set(handles.et_EpochLength,...
    'Callback', {@updateEpochLength});

set(handles.et_Scale,...
    'Callback', {@updateScale});

set(handles.bg_Scoring,...
    'SelectionChangeFcn', {@updateStage});

set(handles.Figure,...
    'KeyPressFcn', {@cb_KeyPressed,});

%% Make Figure Visible and Maximise
set(handles.Figure, 'Visible', 'on');
drawnow; pause(0.001)
jFrame = get(handle(handles.Figure),'JavaFrame');
jFrame.setMaximized(true);   % to maximize the figure

guidata(handles.Figure, handles) 

% Menu Functions
% ``````````````
function menu_LoadEEG(hObject, eventdata, handles)

% load dialog box with file type
[dataFile, dataPath] = uigetfile('*.set', 'Please Select Sleep Data');

% just return if no datafile was actually selected
if isequal(dataFile, 0)
    set(handles.StatusBar, 'String', 'Information: No file selected'); drawnow;
    return;
end

% Load the Files
% ``````````````
set(handles.StatusBar, 'String', 'Busy: Loading EEG (May take some time)...'); drawnow;

% load the struct to the workspace
load([dataPath, dataFile], '-mat');
if ~exist('EEG', 'var')
    set(handles.StatusBar, 'String', 'Warning: No EEG structure found in file'); drawnow;
    return;
end

% memory map the actual data...
tmp = memmapfile(EEG.data,...
                'Format', {'single', [EEG.nbchan EEG.pnts EEG.trials], 'eegData'});
eegData = tmp.Data.eegData;
% eegData = mmo(EEG.data, [EEG.nbchan EEG.pnts EEG.trials], false);
% EEG = pop_loadset([dataPath, dataFile]);

set(handles.StatusBar, 'String', 'EEG Loaded'); drawnow;
set(handles.Figure, 'Name', ['Sleep Scoring: ', dataFile]);

% set the pop-up menus values to the channel labels
try
    set(handles.pmCh, 'String', {EEG.urchanlocs.labels}')
catch
    set(handles.pmCh, 'String', {EEG.chanlocs.labels}')
end

% Check for Previous Scoring
% ``````````````````````````
if isfield(EEG, 'swa_scoring')
    % if there is a previously scoring file
    % set the epochlength
    set(handles.et_EpochLength, 'String', num2str(EEG.swa_scoring.epochLength));  
    sEpoch  = EEG.swa_scoring.epochLength*EEG.srate;
    nEpochs = floor(size(eegData,2)/sEpoch);
else
    % get the default setting for the epoch length from the figure
    EEG.swa_scoring.epochLength = str2double(get(handles.et_EpochLength, 'String'));
    % calculate samples per epoch
    sEpoch  = EEG.swa_scoring.epochLength*EEG.srate; % samples per epoch 
    % calculate number of epochs in the entire series
    nEpochs = floor(size(eegData,2)/sEpoch);
    
    % pre-allocate the variables
    % each sample is assigned a stage (255 is default unscored)
    EEG.swa_scoring.stages      = uint8(ones(1,EEG.pnts)*255);
    EEG.swa_scoring.arousals    = logical(zeros(1,EEG.pnts)*255);    
    % only every epoch is assigned a name
    EEG.swa_scoring.stageNames  = cell(1,nEpochs);
    EEG.swa_scoring.stageNames(:) = {'Unscored'};
    % the montage just indicates which channels are displayed
    EEG.swa_scoring.montage     = 1:8;
end

% Initial plot of the data
% ````````````````````````
% get the default scale
ylimits = str2double(get(handles.et_Scale, 'String'));

% set the limits of all the axes
set(handles.axCh,...
    'XLim', [1, sEpoch],...
    'YLim', [-ylimits,ylimits]);

% initial plot on each axes
data = eegData(EEG.swa_scoring.montage,1:sEpoch);

for i = 1:8
    % re-set the channel labels accordingly
    set(handles.pmCh(i), 'Value', EEG.swa_scoring.montage(i));
    % plot the channel from the first sample on
%     handles.plCh(i) = plot(handles.axCh(i), data(i,:), 'b');
    handles.plCh(i) = line(1:sEpoch, data(i,:), 'color', 'b', 'parent', handles.axCh(i));
end

% plot the arousals 
data(3,  ~EEG.swa_scoring.arousals(1:sEpoch)) = nan;
handles.current_events = line(1:sEpoch, data(3, :), 'color', 'r', 'parent', handles.axCh(3));
    
% Set Slider Values
% `````````````````
% edit the java objects directly using object traversal (ie, .set)
handles.java.Slider.setValue(1);
handles.java.Slider.setMaximum(nEpochs);
handles.java.Slider.setMinorTickSpacing(10);
handles.java.Slider.setMajorTickSpacing(50);
handles.java.Slider.setPaintTicks(true);
% handles.java.Slider.setPaintLabels(false);
handles.java.Slider.setPaintLabels(true);

% Set Hypnogram
% `````````````
time = [1:EEG.pnts]/EEG.srate/60/60;

% set the x-limit to the number of stages
set(handles.axHypno,...
    'XLim', [0 time(end)],...
    'YLim', [0 5]);
   
% plot the stages    
handles.plHypno = plot(time, EEG.swa_scoring.stages,...
    'LineWidth', 2,...
    'Color',    'k');
% ``````````````

% enable the menu items
set(handles.menu.Export, 'Enable', 'on');
set(handles.menu.Statistics, 'Enable', 'on');
% set(handles.menu.Tools, 'Enable', 'on');

% reset the status bar
set(handles.StatusBar, 'String', 'Idle')

% update the handles structure
guidata(handles.Figure, handles)
% use setappdata for data storage to avoid passing it around in handles when not necessary
setappdata(handles.Figure, 'EEG', EEG);
setappdata(handles.Figure, 'eegData', eegData);

% check the filter settings and adjust plots
CheckFilter(hObject, eventdata, 2)

function menu_SaveEEG(hObject, eventdata)
handles = guidata(hObject); % Get handles

set(handles.StatusBar, 'String', 'Saving Dataset')

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

% since the data has not changed we can just save the EEG part, not the data
save([EEG.filepath, '/' EEG.filename], 'EEG', '-mat');

set(handles.StatusBar, 'String', 'Idle')

function menu_Export(hObject, eventdata, stage)
handles = guidata(hObject); % Get handles

% get the eegData structure out of the figure
EEG = getappdata(handles.Figure, 'EEG');
eegData = getappdata(handles.Figure, 'eegData');

% Interpolate the scoring for each sample...
KeepSamples = find(EEG.swa_sleep_c==stage);

if isempty(KeepSamples)
    set(handles.StatusBar, 'String', ['Cannot Export: No epochs found for stage ', num2str(stage)])
    return;
end

switch stage
    case 2
        Data.N2  = double(eegData(:, KeepSamples));
    case 3
        Data.SWS = double(eegData(:, KeepSamples));
    case 5
        Data.REM = double(eegData(:, KeepSamples));        
end

Info.Electrodes = EEG.chanlocs;
Info.sRate      = EEG.srate;

[saveName,savePath] = uiputfile('*.mat');
if ~isempty(saveName)
    set(handles.StatusBar, 'String', 'Busy: Exporting Data')
    save([savePath, saveName], 'Data', 'Info', '-mat')
    set(handles.StatusBar, 'String', 'Idle')
end


% Update Functions
% ````````````````
function updateAxes(handles)
% get the eegData structure out of the figure
EEG = getappdata(handles.Figure, 'EEG');
eegData = getappdata(handles.Figure, 'eegData');

% data section
sEpoch  = str2double(get(handles.et_EpochLength, 'String'))*EEG.srate; % samples per epoch
cEpoch  = handles.java.Slider.getValue;
range   = (cEpoch*sEpoch-(sEpoch-1)):(cEpoch*sEpoch);

data = eegData(EEG.swa_scoring.montage, range);
% filter the data; a and b parameters were computed and stored in the Checkfilter function
data = single(filtfilt(EEG.filter.b, EEG.filter.a, double(data'))'); %transpose data twice

% plot the new data
for i = 1:8
    set(handles.plCh(i), 'Ydata', data(i,:));
end

% plot the events
event = data(3, :);
event(:, ~EEG.swa_scoring.arousals(range)) = nan;
set(handles.current_events, 'yData', event);

function ChangeChannel(hObject, eventdata)
handles = guidata(hObject); % Get handles

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

EEG.swa_scoring.montage(get(hObject, 'UserData')) = get(hObject, 'Value');

% reset the control so focus is on the figure
set(hObject, 'Enable', 'off'); drawnow; set(hObject, 'Enable', 'on'); 

% update the guidata
guidata(hObject, handles)
setappdata(handles.Figure, 'EEG', EEG);

updateAxes(handles)

function sliderUpdate(hObject, eventdata, figurehandle)
% get the handles from the guidata
    % use the handle for the figure since slider is a java object
handles = guidata(figurehandle);

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

% check if the value is less than 1, and set to 1
if handles.java.Slider.getValue < 1
    handles.java.Slider.setValue(1);
end

% set the stage name to the current stage
set(handles.StageBar, 'String', [num2str(handles.java.Slider.getValue),': ', EEG.swa_scoring.stageNames{handles.java.Slider.getValue}]);

% update the GUI handles (*updates just fine)
guidata(handles.Figure, handles)
setappdata(handles.Figure, 'EEG', EEG);

% update all the axes
updateAxes(handles);

function updateScale(hObject, eventdata)
handles = guidata(hObject); % Get handles

% Get the new scale value
ylimits = str2double(get(handles.et_Scale, 'String'));

% Update all the axis to the new scale limits
set(handles.axCh,...
    'YLim', [-ylimits, ylimits]);

function updateStage(hObject, eventdata)
% get the updated handles from the GUI
handles = guidata(hObject);

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

% current epoch range
sEpoch  = str2double(get(handles.et_EpochLength, 'String'))*EEG.srate; % samples per epoch
cEpoch  = handles.java.Slider.getValue;
range   = (cEpoch*sEpoch-(sEpoch-1)):(cEpoch*sEpoch);

% set the current sleep stage value and name
EEG.swa_scoring.stages(range) = get(get(handles.bg_Scoring, 'SelectedObject'), 'UserData');
EEG.swa_scoring.stageNames{handles.java.Slider.getValue} = get(get(handles.bg_Scoring, 'SelectedObject'), 'String');

% reset the scoring box
set(handles.bg_Scoring,'SelectedObject',[]);  % No selection

% change the scores value
set(handles.plHypno, 'Ydata', EEG.swa_scoring.stages);

% get focus back to the figure (bit of a hack)
% set(handles.rb, 'Enable', 'off'); drawnow; set(handles.rb, 'Enable', 'on');

% Update the handles in the GUI
guidata(handles.Figure, handles)
setappdata(handles.Figure, 'EEG', EEG);

% go to the next epoch
handles.java.Slider.setValue(handles.java.Slider.getValue+1)
sliderUpdate(hObject, eventdata, handles.Figure)

function updateEpochLength(hObject, eventdata)
% get handles
handles = guidata(hObject); 

% get the eegData structure out of the figure
EEG = getappdata(handles.Figure, 'EEG');
eegData = getappdata(handles.Figure, 'eegData');

% check for minimum (5s) and maximum (120s) and give warning...
if str2double(get(handles.et_EpochLength, 'String')) > 120
    set(handles.StatusBar, 'String', 'No more than 120s Epochs')
    set(handles.et_EpochLength, 'String', '120')
    return;
elseif str2double(get(handles.et_EpochLength, 'String')) < 5
    set(handles.StatusBar, 'String', 'No less than 5s Epochs')
    set(handles.et_EpochLength, 'String', '5')    
    return;
end

% set the new epoch length
EEG.swa_scoring.epochLength = str2double(get(handles.et_EpochLength, 'String'));

% calculate the number of samples per epoch
sEpoch  = str2double(get(handles.et_EpochLength, 'String'))*EEG.srate;
% calculate the total number of epochs in the time series
nEpochs = floor(size(eegData,2)/sEpoch);

% Set Slider
% ``````````
handles.java.Slider.setMaximum(nEpochs);
% set limit to the axes
% set(handles.axHypno,...
%     'XLim', [1 nEpochs]);
set(handles.axCh,...
    'XLim', [1, sEpoch]);

% re-calculate the stage names from the value (e.g. 0 = wake)
EEG.swa_scoring.stageNames = cell(1,nEpochs);
count = 0;
for i = 1:sEpoch:nEpochs*sEpoch
    count = count+1;
    switch EEG.swa_scoring.stages(i)
        case 0
            EEG.swa_scoring.stageNames(count) = {'Wake'};
        case 1
            EEG.swa_scoring.stageNames(count) = {'N1'};
        case 2
            EEG.swa_scoring.stageNames(count) = {'N2'};
        case 3
            EEG.swa_scoring.stageNames(count) = {'N3'};
        case 5
            EEG.swa_scoring.stageNames(count) = {'REM'};
        otherwise
            EEG.swa_scoring.stageNames(count) = {'Unscored'};
    end
end

set(handles.StatusBar, 'String', 'Idle')

% update the GUI handles
guidata(handles.Figure, handles) 
setappdata(handles.Figure, 'EEG', EEG);

% set the xdata and ydata to equal lengths
for i = 1:8
    set(handles.plCh(i), 'Xdata', 1:sEpoch, 'Ydata', 1:sEpoch);
end
set(handles.current_events, 'Xdata', 1:sEpoch, 'Ydata', 1:sEpoch);

% update the hypnogram
set(handles.plHypno, 'Ydata', EEG.swa_scoring.stages);

% update all the axes
updateAxes(handles);


function cb_KeyPressed(hObject, eventdata)
% get the updated handles structure (*not updated properly)
handles = guidata(hObject);

% movement keys
switch eventdata.Key
    case 'rightarrow'
        handles.java.Slider.setValue(handles.java.Slider.getValue+1);
        sliderUpdate(hObject, eventdata, handles.Figure)
    case 'leftarrow'
        handles.java.Slider.setValue(handles.java.Slider.getValue-1);
        sliderUpdate(hObject, eventdata, handles.Figure)
    case 'uparrow'
        ylimits = str2double(get(handles.et_Scale, 'String'));
        if ylimits <= 20
            set(handles.et_Scale, 'String', num2str(ylimits/2));           
        else
            set(handles.et_Scale, 'String', num2str(ylimits-20));
        end
        updateScale(hObject, eventdata);
    case 'downarrow'        
        ylimits = str2double(get(handles.et_Scale, 'String'));
        if ylimits < 20
            set(handles.et_Scale, 'String', num2str(ylimits*2));           
        else
            set(handles.et_Scale, 'String', num2str(ylimits+20));
        end
        updateScale(hObject, eventdata);
end

% sleep staging
switch eventdata.Character
    case '0'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(1));
        updateStage(hObject, eventdata);
    case '1'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(2));
        updateStage(hObject, eventdata);
    case '2'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(3));
        updateStage(hObject, eventdata);
    case '3'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(4));
        updateStage(hObject, eventdata);
    case '5'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(5));
        updateStage(hObject, eventdata);
end

guidata(handles.Figure, handles)

function CheckFilter(hObject, eventdata, type)
% get the updated handles structure
handles = guidata(hObject);

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

switch type
    case 1
        if  str2double(get(handles.et_HighPass, 'String')) <= 0
            set(handles.et_HighPass, 'String', num2str(0.5));
            set(handles.StatusBar, 'String', 'Warning: High pass must be more than 0')
        end
    case 2
        if  str2double(get(handles.et_LowPass, 'String')) > EEG.srate/2
            set(handles.et_LowPass, 'String', num2str(EEG.srate/2));
            set(handles.StatusBar, 'String', 'Warning: Low pass must be less than Nyquist frequency')
        end
end

% filter Parameters (Buttersworth)
hPass = str2double(get(handles.et_HighPass, 'String'))/(EEG.srate/2);
lPass = str2double(get(handles.et_LowPass, 'String'))/(EEG.srate/2);
[EEG.filter.b, EEG.filter.a] = butter(2,[hPass lPass]);

setappdata(handles.Figure, 'EEG', EEG);
updateAxes(handles)

function menu_Filter(hObject, eventdata)
% Note: doesn't seem to work with memory mapped data

% get the updated handles structure
handles = guidata(hObject);

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

FiPar = inputdlg({'HighPass (Hz)', 'LowPass (Hz)'}, 'Filter Parameters', 1, {'0.5', '30'});

if isempty(FiPar)
    return;
end

hpass = str2double(FiPar{1});
lpass = str2double(FiPar{2});

set(handles.StatusBar, 'String', 'Busy: Filtering Dataset')
EEG = pop_eegfiltnew(EEG, hpass, lpass); 

updateAxes(handles)
set(handles.StatusBar, 'String', 'Idle')

% update the handles
guidata(handles.Figure,handles)
setappdata(handles.Figure, 'EEG', EEG);


function menu_LoadMontage(hObject, eventdata)
handles = guidata(hObject); % Get handles

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

[dataFile, dataPath] = uigetfile('*.set', 'Please Select Scored File with Montage');

if isequal(dataFile, 0)
    set(handles.StatusBar, 'String', 'Information: No file selected'); drawnow;
    return;
end

% Load the Files
set(handles.StatusBar, 'String', 'Busy: Loading Montage Data'); drawnow;
nEEG = load([dataPath, dataFile], '-mat'); nEEG = nEEG.EEG;
set(handles.StatusBar, 'String', 'Idle'); drawnow;
try
    EEG.swa_scoring.montage = nEEG.swa_scoring.montage;
catch
    set(handles.StatusBar, 'String', 'Information: No montage found in file'); drawnow;  
end

clear nEEG

for i = 1:8
    set(handles.pmCh(i), 'Value', EEG.swa_scoring.montage(i));
end

updateAxes(handles);
guidata(handles.Figure,handles)
setappdata(handles.Figure, 'EEG', EEG);


% Code for selecting and marking events
% ````````````````````````````````````
function fcn_select_events(~, ~, hObject, event)

H = guidata(hObject); % Get handles

% get the userData if there was some already (otherwise returns empty)
userData = getappdata(H.axCh(3), 'x_range');

% if there was no userData, then pre-allocate the userData
if isempty(userData)
  userData.range = []; % this is a Nx4 matrix with the selection range
  userData.box   = []; % this is a Nx1 vector with the line handle
end

% determine whether the user is currently making a selection
selecting = numel(userData.range)>0 && any(isnan(userData.range(end,:)));

% get the current point
p = get(H.axCh(3), 'CurrentPoint');
p = p(1,1:2);

xLim = get(H.axCh(3), 'xlim');
yLim = get(H.axCh(3), 'ylim');

% limit cursor coordinates to axes...
if p(1)<xLim(1), p(1)=xLim(1); end;
if p(1)>xLim(2), p(1)=xLim(2); end;
if p(2)<yLim(1), p(2)=yLim(1); end;
if p(2)>yLim(2), p(2)=yLim(2); end;

switch lower(event)
  
  case lower('ButtonDown')        
      if ~isempty(userData.range)
          if any(p(1)>=userData.range(:,1) & p(1)<=userData.range(:,2))
              % the user has clicked in one of the existing selections
              
              fcn_mark_event(H.Figure, userData, get(gcf,'selectiontype'));
              
              % refresh the axes
              updateAxes(H);
              
%               % after box has been clicked delete the box
%               delete(userData.box(ishandle(userData.box)));
%               userData.range = [];
%               userData.box   = [];
          end
      end
      
      % set the figure's windowbuttonmotionfunction
      set(H.Figure, 'WindowButtonMotionFcn', {@fcn_select_events, hObject, 'Motion'});
      % set the figure's windowbuttonupfunction
      set(H.Figure, 'WindowButtonUpFcn',     {@fcn_select_events, hObject, 'ButtonUp'});
      
      % add a new selection range
      userData.range(end+1,1:4) = nan;
      userData.range(end,1) = p(1);
      userData.range(end,3) = p(2);
      
      % add a new selection box
      xData = [nan nan nan nan nan];
      yData = [nan nan nan nan nan];
      userData.box(end+1) = line(xData, yData, 'parent', H.axCh(3));
      
  case lower('Motion')
      
    if selecting
      % update the selection box
        x1 = userData.range(end,1);
        x2 = p(1);
        
        % we are only ever interested in the horizontal range
        y1 = yLim(1);
        y2 = yLim(2);
      
      xData = [x1 x2 x2 x1 x1];
      yData = [y1 y1 y2 y2 y1];
      set(userData.box(end), 'xData', xData);
      set(userData.box(end), 'yData', yData);
      set(userData.box(end), 'Color', [0 0 0]);
      set(userData.box(end), 'EraseMode', 'xor');
      set(userData.box(end), 'LineStyle', '--');
      set(userData.box(end), 'LineWidth', 3);
      set(userData.box(end), 'Visible', 'on');
      
    end  
    
  case lower('ButtonUp')

      if selecting
          % select the other corner of the box
          userData.range(end,2) = p(1);
          userData.range(end,4) = p(2);
      end
      
      % if just a single click (point) then delete all the boxes present
      if ~isempty(userData.range) && ~diff(userData.range(end,1:2)) && ~diff(userData.range(end,3:4))
          % start with a new selection
          delete(userData.box(ishandle(userData.box)));
          userData.range = [];
          userData.box   = [];
      end
      
      if ~isempty(userData.range)
          % ensure that the selection is sane
          if diff(userData.range(end,1:2))<0
              userData.range(end,1:2) = userData.range(end,[2 1]);
          end
          if diff(userData.range(end,3:4))<0
              userData.range(end,3:4) = userData.range(end,[4 3]);
          end
          % only select along the x-axis
          userData.range(end,3:4) = [-inf inf];
      end
      
      % set the figure callbacks to empty to avoid unnecessary calls when
      % not in specific plot
        % set the figure's windowbuttonmotionfunction
      set(H.Figure, 'WindowButtonMotionFcn', []);
        % set the figure's windowbuttonupfunction
      set(H.Figure, 'WindowButtonUpFcn',     []);
    
end % switch event

% put the selection back in the figure
setappdata(H.axCh(3), 'x_range', userData);

function fcn_mark_event(figurehandle, userData, type)

% get the figure handles and data
handles = guidata(figurehandle);
EEG     = getappdata(handles.Figure, 'EEG');

cEpoch  = handles.java.Slider.getValue;
sEpoch  = str2double(get(handles.et_EpochLength, 'String'))*EEG.srate; % samples per epoch

for row = 1:size(userData.range, 1)
    range   = (cEpoch*sEpoch-(sEpoch-1))+floor(userData.range(row, 1)):(cEpoch*sEpoch-(sEpoch-1))+ceil(userData.range(row, 2));
    if strcmp(type, 'normal')
        EEG.swa_scoring.arousals(range) = true;
    else
        EEG.swa_scoring.arousals(range) = false;
    end
end

guidata(handles.Figure, handles);
setappdata(handles.Figure, 'EEG', EEG);
% ```````````````````````````````````