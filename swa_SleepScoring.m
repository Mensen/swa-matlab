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

handles.menu.Tools = uimenu(handles.Figure, 'Label', 'Tools', 'Enable', 'off');
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
handles.java.Slider = javax.swing.JSlider;
set(handles.java.Slider,...
    'Background', [1,1,1]);
[jh,handles.sl_Epochs] = javacomponent(handles.java.Slider);
set(handles.sl_Epochs,...
    'Parent',   handles.Figure,...      
    'Units',    'normalized',...
    'Position', [0.147 0.23 0.756 0.05]);
set(jh, 'MouseReleasedCallback',{@sliderUpdate, handles.Figure});
  
%% Create PopUpMenus and Axes
for i = 1:8
	handles.axCh(i) = axes(...
        'Parent', handles.Figure,...
        'Position', [0.15 (9-i)*0.08+0.225 0.75 0.08],...
        'NextPlot', 'add',...
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
    'String',   'Unscored',...
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

guidata(handles.Figure,handles) 


function menu_LoadEEG(hObject, eventdata, handles)

% !Load dialog box with file type

[dataFile, dataPath] = uigetfile('*.set', 'Please Select Sleep Data');

if isequal(dataFile, 0)
    set(handles.StatusBar, 'String', 'Information: No file selected'); drawnow;
    return;
end

% Load the Files
set(handles.Figure, 'Name', ['Sleep Scoring: ', dataFile]);

set(handles.StatusBar, 'String', 'Busy: Loading EEG (May take some time)...'); drawnow;
handles.EEG = pop_loadset([dataPath, dataFile]);
set(handles.StatusBar, 'String', 'EEG Loaded')

set(handles.pmCh, 'String', {handles.EEG.chanlocs.labels}')

%% Check for Previous Scoring
if isfield(handles.EEG, 'SleepScoring')
    set(handles.et_EpochLength, 'String', num2str(handles.EEG.SleepScoring.EpochLength));  
    sEpoch  = handles.EEG.SleepScoring.EpochLength*handles.EEG.srate;
    nEpochs = floor(size(handles.EEG.data,2)/sEpoch);
else
    handles.EEG.SleepScoring.EpochLength = str2double(get(handles.et_EpochLength, 'String'));
    sEpoch  = str2double(get(handles.et_EpochLength, 'String'))*handles.EEG.srate; % samples per epoch 
    nEpochs = floor(size(handles.EEG.data,2)/sEpoch);
    handles.EEG.SleepScoring.Stages = nan(1,nEpochs);
    handles.EEG.SleepScoring.StageNames = cell(1,nEpochs);
    handles.EEG.SleepScoring.StageNames(:) = {'Unscored'};
    handles.EEG.SleepScoring.Montage = 1:8;
end

%% Plot the data

ylimits = str2double(get(handles.et_Scale, 'String'));
set(handles.axCh,...
    'YLim', [-ylimits,ylimits]);

for i = 1:8
    handles.plCh(i) = plot(handles.axCh(i),...
        handles.EEG.data(handles.EEG.SleepScoring.Montage(i),1:sEpoch), 'b');
    set(handles.pmCh(i), 'Value', handles.EEG.SleepScoring.Montage(i));
end

%% Set Slider Values
handles.java.Slider.setValue(1);
% handles.java.Slider.setMinimum(1);
handles.java.Slider.setMaximum(nEpochs);
handles.java.Slider.setMinorTickSpacing(10);
handles.java.Slider.setMajorTickSpacing(50);
handles.java.Slider.setPaintTicks(true);
% handles.java.Slider.setPaintLabels(false);
handles.java.Slider.setPaintLabels(true);

%% Set Hypnogram
set(handles.axHypno,...
    'XLim', [1 nEpochs]);

handles.plHypno = plot(handles.EEG.SleepScoring.Stages,...
    'LineWidth', 2,...
    'Color',    'k');

set(handles.menu.Export, 'Enable', 'on');
set(handles.menu.Statistics, 'Enable', 'on');
set(handles.menu.Tools, 'Enable', 'on');

set(handles.StatusBar, 'String', 'Idle')
guidata(handles.Figure,handles) 
CheckFilter(hObject,eventdata,2)

function menu_SaveEEG(hObject, eventdata)
handles = guidata(hObject); % Get handles

set(handles.StatusBar, 'String', 'Saving Dataset')
pop_saveset( handles.EEG );
set(handles.StatusBar, 'String', 'Idle')

function menu_Export(hObject, eventdata, stage)
handles = guidata(hObject); % Get handles

% Interpolate the scoring for each sample...
StagesBySample = interp1(1:length(handles.EEG.SleepScoring.Stages), handles.EEG.SleepScoring.Stages, linspace(1,length(handles.EEG.SleepScoring.Stages), handles.EEG.srate*handles.EEG.SleepScoring.EpochLength*length(handles.EEG.SleepScoring.Stages)), 'nearest');
KeepSamples = find(StagesBySample==stage);

if isempty(KeepSamples)
    set(handles.StatusBar, 'String', ['Cannot Export: No epochs found for stage ', num2str(stage)])
    return;
end

switch stage
    case 2
        Data.N2  = double(handles.EEG.data(:, KeepSamples));
    case 3
        Data.SWS = double(handles.EEG.data(:, KeepSamples));
    case 5
        Data.REM = double(handles.EEG.data(:, KeepSamples));        
end

Info.Electrodes = handles.EEG.chanlocs;
Info.sRate      = handles.EEG.srate;

[saveName,savePath] = uiputfile('*.mat');
if ~isempty(saveName)
    set(handles.StatusBar, 'String', 'Busy: Exporting Data')
    save([savePath, saveName], 'Data', 'Info', '-mat')
    set(handles.StatusBar, 'String', 'Idle')
end


function ChangeChannel(hObject, eventdata)
handles = guidata(hObject); % Get handles

handles.EEG.SleepScoring.Montage(get(hObject, 'UserData')) = get(hObject, 'Value');
updateAxes(handles)

% reset the control so focus is on the figure
set(hObject, 'Enable', 'off'); drawnow; set(hObject, 'Enable', 'on'); 
guidata(hObject,handles) 

function sliderUpdate(hObject, eventdata, Figure)
handles = guidata(Figure); % Needs to be like this because slider is a java object

if handles.java.Slider.getValue == 0
    handles.java.Slider.setValue(1);
end

updateAxes(handles);

set(handles.StageBar, 'String', handles.EEG.SleepScoring.StageNames{handles.java.Slider.getValue});

function updateEpochLength(hObject, eventdata)

handles = guidata(hObject); % Get handles

if str2double(get(handles.et_EpochLength, 'String')) > 120
    set(handles.StatusBar, 'String', 'No more than 120s Epochs')
    set(handles.et_EpochLength, 'String', '120')
    return;
elseif str2double(get(handles.et_EpochLength, 'String')) < 5
    set(handles.StatusBar, 'String', 'No less than 5s Epochs')
    set(handles.et_EpochLength, 'String', '5')    
    return;
end


handles.EEG.SleepScoring.EpochLength = str2double(get(handles.et_EpochLength, 'String'));

sEpoch  = str2double(get(handles.et_EpochLength, 'String'))*handles.EEG.srate; % samples per epoch
nEpochs = floor(size(handles.EEG.data,2)/sEpoch);

%% Interpolate the Stages
oldStages = handles.EEG.SleepScoring.Stages;
handles.EEG.SleepScoring.Stages = interp1(1:length(oldStages), oldStages, linspace(1,length(oldStages),nEpochs), 'nearest');

% Plot interpolated staging to Hypnograph...
set(handles.plHypno,...
    'Ydata', handles.EEG.SleepScoring.Stages);

%% Set Slider
handles.java.Slider.setMaximum(nEpochs);
set(handles.axHypno,...
    'XLim', [1 nEpochs]);

for i = 1:8
    updateAxes(handles, get(handles.pmCh(i), 'Value'), i)
end

% Redo the stage names
handles.EEG.SleepScoring.StageNames = cell(1,nEpochs);
for i = 1:nEpochs
    switch handles.EEG.SleepScoring.Stages(i)
        case 0
            handles.EEG.SleepScoring.StageNames(i) = {'Wake'};
        case 1
            handles.EEG.SleepScoring.StageNames(i) = {'N1'};
        case 2
            handles.EEG.SleepScoring.StageNames(i) = {'N2'};
        case 3
            handles.EEG.SleepScoring.StageNames(i) = {'N3'};
        case 5
            handles.EEG.SleepScoring.StageNames(i) = {'N4'};
        otherwise
            handles.EEG.SleepScoring.StageNames(i) = {'Unscored'};
    end
end 


set(handles.StatusBar, 'String', 'Idle')
guidata(handles.Figure,handles) 
 
function updateScale(hObject, eventdata)
handles = guidata(hObject); % Get handles

ylimits = str2double(get(handles.et_Scale, 'String'));

set(handles.axCh,...
    'YLim', [-ylimits,ylimits]);

function updateStage(hObject, eventdata)
handles = guidata(hObject); % Get handles

handles.EEG.SleepScoring.Stages(handles.java.Slider.getValue) = get(get(handles.bg_Scoring, 'SelectedObject'), 'UserData');
handles.EEG.SleepScoring.StageNames{handles.java.Slider.getValue} = get(get(handles.bg_Scoring, 'SelectedObject'), 'String');

handles.java.Slider.setValue(handles.java.Slider.getValue+1)
sliderUpdate(hObject, eventdata, handles.Figure)
set(handles.bg_Scoring,'SelectedObject',[]);  % No selection

set(handles.plHypno,...
    'Ydata', handles.EEG.SleepScoring.Stages);

set(handles.rb, 'Enable', 'off');drawnow;set(handles.rb, 'Enable', 'on');
guidata(handles.Figure,handles) 

function updateAxes(handles)

% Data Section
sEpoch  = str2double(get(handles.et_EpochLength, 'String'))*handles.EEG.srate; % samples per epoch
cEpoch  = handles.java.Slider.getValue;

Data = handles.EEG.data(handles.EEG.SleepScoring.Montage, (cEpoch*sEpoch-(sEpoch-1)):(cEpoch*sEpoch));

% Filter Parameters (Buttersworth)
hPass = str2double(get(handles.et_HighPass, 'String'))/(handles.EEG.srate/2);
lPass = str2double(get(handles.et_LowPass, 'String'))/(handles.EEG.srate/2);
[b,a] = butter(2,[hPass lPass]);

Data = filtfilt(b, a, Data')'; %transpose data twice

for i = 1:8
    set(handles.plCh(i), 'Ydata', Data(i,:));
end


function cb_KeyPressed(hObject, eventdata)
handles = guidata(hObject); % Get handles

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

function CheckFilter(hObject, eventdata, type)
handles = guidata(hObject); % Get handles

switch type
    case 1
        if  str2double(get(handles.et_HighPass, 'String')) <= 0
            set(handles.et_HighPass, 'String', num2str(0.5));
            set(handles.StatusBar, 'String', 'Warning: High pass must be more than 0')
        end
    case 2
        if  str2double(get(handles.et_LowPass, 'String')) > handles.EEG.srate/2
            set(handles.et_LowPass, 'String', num2str(handles.EEG.srate/2));
            set(handles.StatusBar, 'String', 'Warning: Low pass must be less than Nyquist frequency')
        end
end

updateAxes(handles)

function menu_Filter(hObject, eventdata)
handles = guidata(hObject); % Get handles

FiPar = inputdlg({'HighPass (Hz)', 'LowPass (Hz)'}, 'Filter Parameters', 1, {'0.5', '30'});

if isempty(FiPar)
    return;
end

hpass = str2double(FiPar{1});
lpass = str2double(FiPar{2});

set(handles.StatusBar, 'String', 'Busy: Filtering Dataset')
handles.EEG = pop_eegfiltnew(handles.EEG, hpass, lpass); 

updateAxes(handles)
set(handles.StatusBar, 'String', 'Idle')
guidata(handles.Figure,handles) 

function menu_LoadMontage(hObject, eventdata)
handles = guidata(hObject); % Get handles

[dataFile, dataPath] = uigetfile('*.set', 'Please Select Scored File with Montage');

if isequal(dataFile, 0)
    set(handles.StatusBar, 'String', 'Information: No file selected'); drawnow;
    return;
end

% Load the Files
set(handles.StatusBar, 'String', 'Busy: Loading Montage Data'); drawnow;
Data = pop_loadset([dataPath, dataFile]);
set(handles.StatusBar, 'String', 'Idle'); drawnow;
try
    handles.EEG.SleepScoring.Montage = Data.SleepScoring.Montage;
catch
    set(handles.StatusBar, 'String', 'Information: No montage found in file'); drawnow;  
end

clear Data

for i = 1:8
    set(handles.pmCh(i), 'Value', handles.EEG.SleepScoring.Montage(i));
end

updateAxes(handles);
guidata(handles.Figure,handles) 

