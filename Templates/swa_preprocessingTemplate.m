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
fileName, filePath] = uigetfile('*.set');
load([filePath, fileName], '-mat');

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

% load the specific dataset
% [fileName, filePath] = uigetfile('*.set');
EEG = pop_loadset();

% filter the data
EEG = pop_eegfiltnew(EEG, 0.3, 40, [], 0, [], 0);

% take a look at the data manually
eegplot(EEG.data);

% removing bad data
% `````````````````

% bad channels
    % find channels based on stds for spectral windows (better)
    [~, EEG.badchannels, EEG.specdata] = pop_rejchanspec(EEG,...
        'freqlims', [20 40]     ,...
        'stdthresh',[-3.5 3.5]  ,...
        'plothist', 'off'        );

    % remove the bad channels found
    EEG = eeg_interp(EEG, EEG.badchannels);

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
%     [EEG, badregions] = pop_rejcont(EEG,...
%         'epochlength',  20,...
%         'threshold',    10,...
%         'contiguous',   2,...
%         'addlength',    0.5,...
%         'onlyreturnselection', 'on',...
%         'verbose',      'off');

% ``````````````````

% run ICA (optional)
% EEG = pop_runica(EEG, 'extended', 1, 'interupt', 'off');

% remove the components (best to do using plot component properties in the GUI)


% change reference
% ````````````````
% average reference
EEG = pop_reref( EEG, [],...
    'refloc', EEG.chaninfo.nodatchans(:));

% linked mastoid
% mastoids = [94, 190];
% EEG = pop_reref(EEG, mastoids);

% save the data
EEG = pop_saveset(EEG);
