%% -- Manual Sleep Scoring GUI -- %%
function swa_SleepScoring(varargin)
% GUI to score sleep stages and save the results for further
% processing (e.g. travelling waves analysis)

% Author: Armand Mensen

DefineInterface

function DefineInterface
handles.Figure = figure(...
    'Name',         'Sleep Scoring',...
    'NumberTitle',  'off',...
    'Color',        'w',...
    'MenuBar',      'none',...
    'Units',        'normalized',...
    'Outerposition',[0 0.04 .5 0.96]);
set(handles.Figure, 'CloseRequestFcn', {@fcn_close_request});

%% Menus
handles.menu.File = uimenu(handles.Figure, 'Label', 'File');
handles.menu.LoadEEG = uimenu(handles.menu.File,...
    'Label', 'Load EEG',...
    'Accelerator', 'L');
handles.menu.SaveEEG = uimenu(handles.menu.File,...
    'Label', 'Save EEG',...
    'Accelerator', 'S');

handles.menu.Montage      = uimenu(handles.Figure, 'Label', 'Montage', 'Enable', 'off');

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

% Hidden epoch tracker
% ````````````````````
handles.cEpoch = uicontrol(...
    'Parent',   handles.Figure,...
    'Style',    'text',...
    'Visible',  'off',...
    'Value',    1);
    
% Create PopUpMenus and Axes
% ``````````````````````````
for i = 1:8
	handles.axCh(i) = axes(...
        'Parent', handles.Figure,...
        'Position', [0.15 (9-i)*0.08+0.225 0.75 0.08],...
        'NextPlot', 'add',...
        'drawmode', 'fast',...
        'FontName', 'Century Gothic',...
        'FontSize', 8);
	handles.lbCh(i) = uicontrol(...
        'Parent',   handles.Figure,...  
        'Style',    'edit',...  
        'BackgroundColor', 'w',...
        'Units',    'normalized',...
        'Position', [0.11 (9-i)*0.08+0.245 0.04 0.04],...
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

% Scoring Buttons
% ```````````````

handles.bg_Scoring = uibuttongroup(...
    'Title','Stage',...
    'FontName', 'Century Gothic',...
    'FontSize', 11,...
    'FontWeight', 'bold',...
    'BackgroundColor', 'w',...
    'Position',[0.92 0.375 0.05 0.5]);
% Create radio buttons in the button group.
handles.rb(1) = uicontrol('Style','radiobutton',...
    'String','wake','UserData', 0,...
    'Units', 'normalized', 'Position',[0.1 11/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(2) = uicontrol('Style','radiobutton',...
    'String','nrem1','UserData', 1,...
    'Units', 'normalized', 'Position',[0.1 9/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(3) = uicontrol('Style','radiobutton',...
    'String','nrem2','UserData', 2,...
    'Units', 'normalized', 'Position',[0.1 7/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(4) = uicontrol('Style','radiobutton',...
    'String','nrem3','UserData', 3,...
    'Units', 'normalized', 'Position',[0.1 5/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(5) = uicontrol('Style','radiobutton',...
    'String','rem', 'UserData', 5,...
    'Units', 'normalized', 'Position',[0.1 3/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');
handles.rb(6) = uicontrol('Style','radiobutton',...
    'String','artifact','UserData', 6,...
    'Units', 'normalized', 'Position',[0.1 1/13 0.9 0.1],...
    'Parent',handles.bg_Scoring,'HandleVisibility','off');

set(handles.bg_Scoring,'SelectedObject',[]);  % No selection
set(handles.rb, 'BackgroundColor', 'w', 'FontName', 'Century Gothic','FontSize', 10);

% Create StageBar
% ```````````````
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

% Create Hyponogram
% `````````````````
handles.axHypno = axes(...
    'Parent', handles.Figure,...
    'Position', [0.15 0.050 0.75 0.20],...
    'YLim',     [0 6.5],...
    'YDir',     'reverse',...
    'YTickLabel', {'wake', 'nrem1', 'nrem2', 'nrem3', '', 'rem', 'artifact'},...
    'NextPlot', 'add',...
    'FontName', 'Century Gothic',...
    'FontSize', 8);

% Epoch Length
% ````````````
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

% Scale
% `````
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

% Set Callbacks
% `````````````
% menu callbacks
set(handles.menu.LoadEEG,...
    'Callback', {@menu_LoadEEG, handles});
set(handles.menu.SaveEEG,...
    'Callback', {@menu_SaveEEG});
set(handles.menu.Montage,...
    'Callback', {@updateMontage, handles.Figure});

% set export callbacks
set(handles.menu.N2,...
    'Callback', {@menu_Export, 2});
set(handles.menu.N3,...
    'Callback', {@menu_Export, 3});
set(handles.menu.REM,...
    'Callback', {@menu_Export, 5});

% set hypnogram click
set(handles.axHypno,...
    'ButtonDownFcn', {@bd_hypnoEpochSelect});

set(handles.lbCh,...
    'Callback', {@updateLabel});

set(handles.et_EpochLength,...
    'Callback', {@updateEpochLength});

set(handles.et_Scale,...
    'Callback', {@updateScale});

set(handles.bg_Scoring,...
    'SelectionChangeFcn', {@updateStage});

set(handles.Figure,...
    'KeyPressFcn', {@cb_KeyPressed,});

% Make Figure Visible and Maximise
% ````````````````````````````````
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

set(handles.Figure, 'Name', ['Sleep Scoring: ', dataFile]);

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

    % assign montage defaults
    EEG.swa_scoring.montage.labels = cell(8,1);
    EEG.swa_scoring.montage.labels(:) = {'undefined'};
    EEG.swa_scoring.montage.channels = [1:8; ones(1,8)*size(eegData,1)]';
    EEG.swa_scoring.montage.filterSettings = [ones(1,8)*0.5; ones(1,8)*30]';
end

% set the labels from the montage
for i = 1:8
    set(handles.lbCh(i), 'string', EEG.swa_scoring.montage.labels{i})
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
data = eegData(EEG.swa_scoring.montage.channels(:,1),1:sEpoch)-eegData(EEG.swa_scoring.montage.channels(:,2),1:sEpoch);

for i = 1:8
    % plot the channel from the first sample on
    handles.plCh(i) = line(1:sEpoch, data(i,:), 'color', 'b', 'parent', handles.axCh(i));
end

% plot the arousals 
data(3,  ~EEG.swa_scoring.arousals(1:sEpoch)) = nan;
handles.current_events = line(1:sEpoch, data(3, :), 'color', 'r', 'parent', handles.axCh(3));

% set the current epoch
set(handles.cEpoch, 'Value', 1);

% Set Hypnogram
% `````````````
time = [1:EEG.pnts]/EEG.srate/60/60;

% set the x-limit to the number of stages
set(handles.axHypno,...
    'XLim', [0 time(end)]);
% plot the epoch indicator line
handles.ln_hypno = line([0, 0], [0, 6.5], 'color', [0.5, 0.5, 0.5], 'parent', handles.axHypno);


% plot the stages    
handles.plHypno = plot(time, EEG.swa_scoring.stages,...
    'LineWidth', 2,...
    'Color',    'k');
% ``````````````

% save the sEpoch to the EEG structure
EEG.swa_scoring.sEpoch = sEpoch;

% enable the menu items
set(handles.menu.Export, 'Enable', 'on');
set(handles.menu.Statistics, 'Enable', 'on');
set(handles.menu.Montage, 'Enable', 'on');

% reset the status bar
set(handles.StatusBar, 'String', 'Idle')

% update the handles structure
guidata(handles.Figure, handles)
% use setappdata for data storage to avoid passing it around in handles when not necessary
setappdata(handles.Figure, 'EEG', EEG);
setappdata(handles.Figure, 'eegData', eegData);

set(handles.StatusBar, 'String', 'EEG Loaded'); drawnow;

% check the filter settings and adjust plots
checkFilter(handles.Figure, [])

function menu_SaveEEG(hObject, eventdata)
handles = guidata(hObject); % Get handles

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

% since the data has not changed we can just save the EEG part, not the data
save([EEG.filepath, EEG.filename], 'EEG', '-mat');

set(handles.StatusBar, 'String', 'Data Saved')

function menu_Export(hObject, eventdata, stage)
handles = guidata(hObject); % Get handles

% get the eegData structure out of the figure
EEG = getappdata(handles.Figure, 'EEG');
eegData = getappdata(handles.Figure, 'eegData');

% Find the matching stage and remove arousal samples
keepSamples = logical(zeros(1,size(EEG.swa_scoring.stages,2)));
keepSamples(EEG.swa_scoring.stages == stage) = true;
keepSamples(EEG.swa_scoring.arousals) = false;

if sum(keepSamples) == 0
    set(handles.StatusBar, 'String', ['Cannot Export: No epochs found for stage ', num2str(stage)])
    return;
end

% copy the data to a new structure
Data.N2  = double(eegData(:, keepSamples));    

% get the necessary info from the EEG
if isempty(EEG.chanlocs)
    Info.Electrodes = EEG.urchanlocs;
else
    Info.Electrodes = EEG.chanlocs;
end
Info.sRate      = EEG.srate;

% calculate the time of each sample
time = (1:size(EEG.swa_scoring.stages,2))/EEG.srate;
Info.time       = time(keepSamples);

[saveName,savePath] = uiputfile('*.mat');
if ~isempty(saveName)
    set(handles.StatusBar, 'String', 'Busy: Exporting Data')
    save([savePath, saveName], 'Data', 'Info', '-mat', '-v7.3')
    set(handles.StatusBar, 'String', 'Idle')
end


% Update Functions
% ````````````````
function updateAxes(handles)
% get the eegData structure out of the figure
EEG = getappdata(handles.Figure, 'EEG');
eegData = getappdata(handles.Figure, 'eegData');

% data section
sEpoch  = EEG.swa_scoring.sEpoch;
cEpoch  = get(handles.cEpoch, 'value');
range   = (cEpoch*sEpoch-(sEpoch-1)):(cEpoch*sEpoch);

data = eegData(EEG.swa_scoring.montage.channels(:,1),range)-eegData(EEG.swa_scoring.montage.channels(:,2),range);
% filter the data; a and b parameters were computed and stored in the checkfilter function

% data = single(filtfilt(EEG.filter.b, EEG.filter.a, double(data'))'); %transpose data twice

% loop for each individual channels settings
% plot the new data
for i = 1:8
    data(i,:) = single(filtfilt(EEG.filter.b(i,:), EEG.filter.a(i,:), double(data(i,:)'))'); %transpose data twice
    set(handles.plCh(i), 'Ydata', data(i,:));
end

% plot the events
event = data(3, :);
event(:, ~EEG.swa_scoring.arousals(range)) = nan;
set(handles.current_events, 'yData', event);

set(handles.StatusBar, 'string',...
   'idle'); drawnow;

function updateLabel(hObject, ~)
handles = guidata(hObject); % Get handles

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

EEG.swa_scoring.montage.labels{get(hObject, 'UserData')} = get(hObject, 'string');

% update the guidata
guidata(hObject, handles)
setappdata(handles.Figure, 'EEG', EEG);

function fcn_epochChange(hObject, eventdata, figurehandle)
% get the handles from the guidata
handles = guidata(figurehandle);

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

cEpoch = get(handles.cEpoch, 'value');
if cEpoch < 1
    set(handles.StatusBar, 'String', 'This is the first epoch')
    set(handles.cEpoch, 'value', 1);
elseif cEpoch > length(EEG.swa_scoring.stageNames)
    set(handles.StatusBar, 'String', 'No further epochs')
    set(handles.cEpoch, 'value', length(EEG.swa_scoring.stageNames));
end
cEpoch = get(handles.cEpoch, 'value');

% update the hypnogram indicator line
x = cEpoch * EEG.swa_scoring.epochLength/60/60;
set(handles.ln_hypno, 'Xdata', [x, x]);

% set the stage name to the current stage
set(handles.StageBar, 'String',...
    [num2str(cEpoch),': ', EEG.swa_scoring.stageNames{cEpoch}]);

% update the GUI handles (*updates just fine)
guidata(handles.Figure, handles)
setappdata(handles.Figure, 'EEG', EEG);

% update all the axes
updateAxes(handles);

function updateScale(hObject, ~)
handles = guidata(hObject); % Get handles

% Get the new scale value
ylimits = str2double(get(handles.et_Scale, 'String'));

% Update all the axis to the new scale limits
set(handles.axCh,...
    'YLim', [-ylimits, ylimits]);

function updateStage(hObject, ~)
% get the updated handles from the GUI
handles = guidata(hObject);

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

% current epoch range
sEpoch  = str2double(get(handles.et_EpochLength, 'String'))*EEG.srate; % samples per epoch
cEpoch  = get(handles.cEpoch, 'value');
range   = (cEpoch*sEpoch-(sEpoch-1)):(cEpoch*sEpoch);

% set the current sleep stage value and name
EEG.swa_scoring.stages(range) = get(get(handles.bg_Scoring, 'SelectedObject'), 'UserData');
EEG.swa_scoring.stageNames{cEpoch} = get(get(handles.bg_Scoring, 'SelectedObject'), 'String');

% reset the scoring box
set(handles.bg_Scoring,'SelectedObject',[]);  % No selection

% change the scores value
set(handles.plHypno, 'Ydata', EEG.swa_scoring.stages);

% get focus back to the figure (bit of a hack)
% set(handles.rb, 'Enable', 'off'); drawnow; set(handles.rb, 'Enable', 'on');

% Update the handles in the GUI
guidata(handles.Figure, handles);
setappdata(handles.Figure, 'EEG', EEG);

% go to the next epoch
set(handles.cEpoch, 'value', cEpoch+1);
fcn_epochChange(hObject, [], handles.Figure);

function updateEpochLength(hObject, ~)
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

% set limit to the axes
% set(handles.axHypno,...
%     'XLim', [1 nEpochs]);
set(handles.axCh,...
    'XLim', [1, sEpoch]);

% re-calculate the stage names from the value (e.g. 0 = wake)
EEG.swa_scoring.stageNames = cell(1, nEpochs);
count = 0;
for i = 1:sEpoch:nEpochs*sEpoch
    count = count+1;
    switch EEG.swa_scoring.stages(i)
        case 0
            EEG.swa_scoring.stageNames(count) = {'wake'};
        case 1
            EEG.swa_scoring.stageNames(count) = {'nrem1'};
        case 2
            EEG.swa_scoring.stageNames(count) = {'nrem2'};
        case 3
            EEG.swa_scoring.stageNames(count) = {'nrem3'};
        case 5
            EEG.swa_scoring.stageNames(count) = {'rem'};
        case 6
            EEG.swa_scoring.stageNames(count) = {'artifact'};
        otherwise
            EEG.swa_scoring.stageNames(count) = {'unscored'};
    end
end

set(handles.StatusBar, 'String', 'Idle')

% set the xdata and ydata to equal lengths
for i = 1:8
    set(handles.plCh(i), 'Xdata', 1:sEpoch, 'Ydata', 1:sEpoch);
end
set(handles.current_events, 'Xdata', 1:sEpoch, 'Ydata', 1:sEpoch);

% update the hypnogram
set(handles.plHypno, 'Ydata', EEG.swa_scoring.stages);

% save the sEpoch to the EEG structure
EEG.swa_scoring.sEpoch = sEpoch;

% update the GUI handles
guidata(handles.Figure, handles) 
setappdata(handles.Figure, 'EEG', EEG);

% update all the axes
updateAxes(handles);


function cb_KeyPressed(hObject, eventdata)
% get the updated handles structure (*not updated properly)
handles = guidata(hObject);

% movement keys
switch eventdata.Key
    case 'rightarrow'
        % move to the next epoch
        set(handles.cEpoch, 'Value', get(handles.cEpoch, 'Value') + 1);
        fcn_epochChange(hObject, eventdata, handles.Figure)
    case 'leftarrow'
        % move to the previous epoch
        set(handles.cEpoch, 'Value', get(handles.cEpoch, 'Value') - 1);
        fcn_epochChange(hObject, eventdata, handles.Figure)
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
    case '6'
        set(handles.bg_Scoring,'SelectedObject',handles.rb(6));
        updateStage(hObject, eventdata);
end

guidata(handles.Figure, handles)

function checkFilter(figureHandle, ~)
% get the updated handles structure
handles = guidata(figureHandle);

% User feedback since this often takes some time
set(handles.StatusBar, 'string',...
    'Checking filter parameters'); drawnow;

% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

% switch type
%     case 1
%         if  str2double(get(handles.et_HighPass, 'String')) <= 0
%             set(handles.et_HighPass, 'String', num2str(0.5));
%             set(handles.StatusBar, 'String', 'Warning: High pass must be more than 0')
%         end
%     case 2
%         if  str2double(get(handles.et_LowPass, 'String')) > EEG.srate/2
%             set(handles.et_LowPass, 'String', num2str(EEG.srate/2));
%             set(handles.StatusBar, 'String', 'Warning: Low pass must be less than Nyquist frequency')
%         end
% end
% 
% % filter Parameters (Buttersworth)
% hPass = str2double(get(handles.et_HighPass, 'String'))/(EEG.srate/2);
% lPass = str2double(get(handles.et_LowPass, 'String'))/(EEG.srate/2);
% [EEG.filter.b, EEG.filter.a] = butter(2,[hPass lPass]);

% loop each channel for their individual settings
for i = 1:8
    [EEG.filter.b(i,:), EEG.filter.a(i,:)] = ...
        butter(2,[EEG.swa_scoring.montage.filterSettings(i,1)/(EEG.srate/2),...
                  EEG.swa_scoring.montage.filterSettings(i,2)/(EEG.srate/2)]);
end
    
% save EEG struct back into the figure
setappdata(handles.Figure, 'EEG', EEG);

% update the axes with the new filters
updateAxes(handles)

function bd_hypnoEpochSelect(hObject, ~)
% function when the user clicks in the hypnogram

% get the handles
handles = guidata(hObject);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.Figure, 'EEG');

current_point = get(handles.axHypno, 'CurrentPoint');

cEpoch = floor(current_point(1)*60*60*EEG.srate/EEG.swa_scoring.sEpoch);

% set the current epoch
set(handles.cEpoch, 'value', cEpoch);

% Update the handles in the GUI
guidata(handles.Figure, handles)

% update the figure
fcn_epochChange(hObject, [], handles.Figure);



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

cEpoch  = get(handles.cEpoch, 'value');
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


% Montage Options
% ```````````````
function updateMontage(~, ~, figurehandle)

% create the figure
H.Figure = figure(...
    'Name',         'Montage Settings',...
    'NumberTitle',  'off',...
    'Color',        'w',...
    'MenuBar',      'none',...
    'Units',        'normalized',...
    'Outerposition',[0.2 0.2 0.2 0.4]);

% create label boxes
defaults = {'LOC', 'ROC', 'Fz', 'C3', 'C4', 'O1', 'O2', 'EMG'};
for i = 1:8
    H.lbCh(i) = uicontrol(...
        'Parent',        H.Figure,...
        'Style',         'edit',...
        'BackgroundColor', 'w',...
        'Units',        'normalized',...
        'Position',     [0.1 (9-i)*0.1+0.025 0.125 0.04],...
        'String',       defaults{i},...
        'FontName',     'Century Gothic',...
        'FontSize',     8);
end

% create popup menus and axes
for i = 1:8
	H.pmCh(i) = uicontrol(...
        'Parent',   H.Figure,...  
        'Style',    'popupmenu',...  
        'BackgroundColor', 'w',...
        'Units',    'normalized',...
        'Position', [0.3 (9-i)*0.1+0.025 0.125 0.04],...
        'String',   ['Channel ', num2str(i)],...
        'UserData',  i,...
        'FontName', 'Century Gothic',...
        'FontSize', 8);
	H.pmRe(i) = uicontrol(...
        'Parent',   H.Figure,...  
        'Style',    'popupmenu',...  
        'BackgroundColor', 'w',...
        'Units',    'normalized',...
        'Position', [0.45 (9-i)*0.1+0.025 0.125 0.04],...
        'String',   ['Channel ', num2str(i)],...
        'UserData',  i,...
        'FontName', 'Century Gothic',...
        'FontSize', 8);
end

% create filter boxes
for i = 1:8
    H.lbHP(i) = uicontrol(...
        'Parent',        H.Figure,...
        'Style',         'edit',...
        'BackgroundColor', 'w',...
        'Units',        'normalized',...
        'Position',     [0.65 (9-i)*0.1+0.025 0.125 0.04],...
        'String',       '0.5',...
        'UserData',     0.5,...
        'FontName',     'Century Gothic',...
        'FontSize',     8);
    H.lbLP(i) = uicontrol(...
        'Parent',        H.Figure,...
        'Style',         'edit',...
        'BackgroundColor', 'w',...
        'Units',        'normalized',...
        'Position',     [0.8 (9-i)*0.1+0.025 0.125 0.04],...
        'String',       '30',...
        'UserData',     30,...
        'FontName',     'Century Gothic',...
        'FontSize',     8);    
end

% menu options
H.menu.Open = uimenu(H.Figure, 'Label', 'Open');
H.menu.Save = uimenu(H.Figure, 'Label', 'Apply');
H.menu.Plot = uimenu(H.Figure, 'Label', 'Plot');

setMontageData(H, figurehandle)

function setMontageData(H, figureHandle)
% get the figure handles and data
handles = guidata(figureHandle);
EEG     = getappdata(handles.Figure, 'EEG');

% set the channel options in the pop-menu
try
    set([H.pmCh; H.pmRe], 'String', {EEG.urchanlocs.labels}')
catch
    set([H.pmCh; H.pmRe], 'String', {EEG.chanlocs.labels}')
end

% check if the input already has these files and change them
if isfield(EEG.swa_scoring, 'montage')
    % set the labels
    for i = 1:8
        set(H.lbCh(i), 'string', EEG.swa_scoring.montage.labels{i});
        set(H.pmCh(i), 'Value',  EEG.swa_scoring.montage.channels(i,1));
        set(H.pmRe(i), 'Value',  EEG.swa_scoring.montage.channels(i,2));
        set(H.lbHP(i), 'string', num2str(EEG.swa_scoring.montage.filterSettings(i,1)));
        set(H.lbLP(i), 'string', num2str(EEG.swa_scoring.montage.filterSettings(i,2)));
    end
else
    
    
end

% set the callbacks for the menu
set(H.menu.Open,  'Callback', {@openMontage, H, figureHandle});
set(H.menu.Save,  'Callback', {@saveMontage, H, figureHandle});
set(H.menu.Plot,  'Callback', {@plotMontage, H, figureHandle});

function openMontage(~, ~, H, figureHandle)
handles = guidata(figureHandle); % Get handles

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

guidata(handles.Figure,handles)
setappdata(handles.Figure, 'EEG', EEG);

setMontageData(H, figureHandle)

% saving the Montage
function saveMontage(~, ~, H, figureHandle)
% get the data
handles = guidata(figureHandle);
EEG     = getappdata(figureHandle, 'EEG');

% save the selected montage into the EEG structure
EEG.swa_scoring.montage.labels = get(H.lbCh, 'String');
EEG.swa_scoring.montage.channels = cell2mat([get(H.pmCh, 'Value'), get(H.pmRe, 'Value')]);
EEG.swa_scoring.montage.filterSettings = [str2double(get(H.lbHP, 'String')), str2double(get(H.lbLP, 'String'))];

% update all the labels (even if they didn't change)
for i = 1:8
    set(handles.lbCh(i), 'string', EEG.swa_scoring.montage.labels{i})
end

% set the data
guidata(handles.Figure, handles)
setappdata(figureHandle, 'EEG', EEG);

% check the filter settings (calls updateAxes itself)
checkFilter(handles.Figure)

% plot empty channel set
function plotMontage(~, ~, ~, figureHandle)
EEG     = getappdata(figureHandle, 'EEG');

if ~isempty(EEG.chanlocs)
    locs = EEG.chanlocs;
else
    locs = EEG.urchanlocs;
end
   
H = swa_Topoplot(...
    nan(40, 40), locs                                       ,...
    'NewFigure',        1                                   ,...
    'NumContours',      10                                  ,...
    'PlotContour',      1                                   ,...
    'PlotChannels',     1                                   ,...
    'PlotStreams',      0                                   );


% Close request
% `````````````
function fcn_close_request(~, ~)
% User-defined close request function to display a question dialog box
selection = questdlg('Are you sure?',...
    '',...
    'Yes','No','Yes');
switch selection,
    case 'Yes'
        delete(gcf)
    case 'No'
        return
end
