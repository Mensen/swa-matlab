% Import the raw EEG
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% import the raw EEG file 
% (for example from egi raw files)
EEG = pop_readsegegi();

% set the channel locations from file
EEG = pop_chanedit( EEG, 'load',{'/home/mensen/Research/Data/swa/StandardDataset/GSN-HydroCel-257.sfp' 'filetype' 'autodetect'}, 'delete', 1, 'delete', 1, 'delete', 1, 'changefield',{257 'datachan' 0});

% save the dataset
EEG = pop_saveset(EEG);

% score the data for sleep stages
swa_SleepScoring;


% After Scoring // Export Stages
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Load the data set
[fileName, filePath] = uigetfile('*.set');
load(fullfile(filePath, fileName), '-mat');

% get the indices for N2
samplesN2 = EEG.swa_scoring.stages == 2;
samplesN2(EEG.swa_scoring.arousals) = false;
swa_selectStagesEEGLAB(EEG, samplesN2, [fileName(1:3), '_N2.set']);

% get indices for N3
samplesN3 = EEG.swa_scoring.stages == 3;
samplesN3(EEG.swa_scoring.arousals) = false;
swa_selectStagesEEGLAB(EEG, samplesN3, [fileName(1:3), '_N3.set']);


% Preprocess the Data
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% * steps can be done within EEGLAB GUI

% clear the memory
clear all; clc;

% load the specific dataset
% [fileName, filePath] = uigetfile('*.set');
EEG = pop_loadset();

% filter the data
EEG = pop_eegfiltnew(EEG, 0.3, 30, [], 0, [], 0);

% removing bad data
% `````````````````
% take a look at the data manually
    eegplot( EEG.data               ,...
        'srate',        EEG.srate   ,...
        'winlength',    30          ,...
        'dispchans',    15          );
    
% bad channels
    % find channels based on stds for spectral windows (better)
    [~, EEG.bad_channels, EEG.specdata] = pop_rejchanspec(EEG,...
        'freqlims', [20 40]     ,...
        'stdthresh',[-3.5 3.5]  ,...
        'plothist', 'off'       );

    % manually remove channels
    EEG.bad_channels = [EEG.bad_channels, ];
    
    % remove the bad channels found
    EEG = pop_select(EEG, 'nochannel', EEG.bad_channels);

% remove bad data segments
    % find the absolute median of the data
    medData = median(abs(EEG.data), 1);

    % mark everything above 8 deviations from that mean
    x = medData > std(medData)*8;
    % plot some bad data...
    plot(1:length(find(x)), EEG.data(:, find(x)), 'color', [0.5 0.5 0.5]);

    % remove those samples from the data
    EEG.data(:, x)          = [];
    EEG.times(x)            = [];
    EEG.pnts                = size(EEG.data, 2);
    EEG                     = eeg_checkset(EEG);

% bad segments based on spectrum
    [~, EEG.bad_regions] = pop_rejcont(EEG,...
        'freqlimit',    [20, 40],...  % lower and upper limits of frequencies
        'epochlength',  5,...         % window size to examine (in s)
        'overlap',      2,...         % amount of overlap in the windows
        'threshold',    10,...        % frequency upper threshold in dB
        'contiguous',   2,...         % number of contiguous epochs necessary to label a region as artifactual
        'addlength',    0.5,...       % seconds to add to each artifact side
        'onlyreturnselection', 'on',... % do not actually remove it, just label it
        'taper',        'hamming',... % taper to use before FFT
        'verbose',      'off');

% bad segments based on frequency analysis    (for epoched data) 
%     [~, EEG.bad_regions] = pop_rejspec(EEG, 1,...
%         'freqlimits',    [20, 40],...  % lower and upper limits of frequencies
%         'method',       'multitaper',... % window size to examine (in s)
%         'threshold',    [-10, 10]);    
    
% plot the first bad region
    window = 2*EEG.srate;
    plot(EEG.data(:, EEG.bad_regions(1,1)-window:EEG.bad_regions(1,2)+window)',...
        'color', [0.8, 0.8, 0.8]);
    
% remove the bad_regions
    EEG = pop_select(EEG, 'nopoint', EEG.bad_regions);


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
% or using the csc_eeg_plotter to mark bad channels and events
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EEG = csc_eeg_plotter(EEG);
EEG.bad_channels{1} = EEG.hidden_channels;

% remove bad channels and trials
EEG = pop_select(EEG, 'nochannel', EEG.bad_channels);

% mark the start and end of bad segments using event 1 and event 2
EEG.bad_segments = [cell2mat(EEG.csc_event_data(1:3, 2)), ...
    cell2mat(EEG.csc_event_data(4:6, 2))];
EEG = pop_select(EEG, 'nopoint', EEG.bad_segments);
   

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% independent components analysis 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% run ICA
EEG = pop_runica(EEG,...
    'icatype', 'binica', ...
    'extended', 1,...
    'interupt', 'off');

% or use the csc_eeg_tools and use the ica option
% remove the components (best to do using plot component properties in the GUI)
csc_eeg_plotter(EEG);
EEG.good_components = csc_component_plot(EEG);

% pop_prop changes the local EEG variable automatically when marked as reject
EEG = pop_subcomp( EEG , find(~EEG.good_components));
EEG = eeg_checkset(EEG);

% interpolate the removed channels
% ````````````````````````````````
[previousFile, previousPath] = uigetfile('*.set');
previousEEG = load(fullfile(previousPath, previousFile), '-mat');
EEG = eeg_interp(EEG, previousEEG.EEG.chanlocs);


% change reference
% ````````````````
% average reference
EEG = pop_reref( EEG, [],...
    'refloc', EEG.chaninfo.nodatchans(:));

% linked mastoid
% mastoids = [94, 190];
% EEG = pop_reref(EEG, mastoids);

% save the data
% `````````````
EEG = pop_saveset(EEG);
