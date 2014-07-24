% Import the raw EEG
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% import the raw EEG file 
% (for example from egi raw files)
EEG = pop_readsegegi();

% set the channel locations from file
EEG = pop_chanedit( EEG, 'load',{'/home/mensen/Research/Data/swa/StandardDataset/GSN-HydroCel-257.sfp' 'filetype' 'autodetect'}, 'delete', 1, 'delete', 1, 'delete', 1, 'changefield',{257 'datachan' 0});

% score the data for sleep stages
swa_SleepScoring;


% After Scoring // Export Stages
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Load the data set
[fileName, filePath] = uigetfile('*.set');
load([filePath, fileName], '-mat');

% get the indices for N2
samplesN2 = EEG.swa_scoring.stages == 2;
samplesN2(EEG.swa_scoring.arousals) = false;

% get indices for N3
samplesN3 = EEG.swa_scoring.stages == 3;
samplesN3(EEG.swa_scoring.arousals) = false;

% save the data in a separate file
swa_selectStagesEEGLAB(EEG, samplesN2, [fileName, 'N2.set']);
swa_selectStagesEEGLAB(EEG, samplesN3, [fileName, 'N3.set']);


% Preprocess the Data
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% * steps can be done within EEGLAB GUI

% load the specific dataset
% [fileName, filePath] = uigetfile('*.set');
EEG = pop_loadset();

% filter the data
EEG = pop_eegfiltnew(EEG, 0.3, 40, [], 0, [], 0);

% removing bad data 
% `````````````````
% remove bad data segments
    % find the absolute median of the data
    medData = median(abs(EEG.data), 1);

    % mark everything above 8 deviations from that mean
    x = medData > std(medData)*8;
    % plot some bad data...
    % plot(1:length(find(x)), EEG.data(:, find(x)), 'color', [0.5 0.5 0.5]);

    % remove those samples from the data
    EEG.data(:, x)          = [];
    EEG.times(x)            = [];
    EEG.pnts                = size(EEG.data, 2);
    EEG                     = eeg_checkset(EEG);

% bad channels
    % remove channels based on stds for spectral windows (better)
    [EEG, EEG.reject.indelec] = pop_rejchanspec(EEG,...
        'freqlims', [10 25; 25 50]      ,...
        'stdthresh', [-15 15; -10 10]   );

% ``````````````````

% run ICA (optional)


% remove the components


% interpolate removed bad channels (or still bad channels)
EEG = eeg_interp(EEG, EEG.reject.indelec);


% change reference
% ````````````````
% average reference
EEG = pop_reref( EEG, [],...
    'refloc', EEG.chaninfo.nodatchans(:));

% linked mastoid
mastoids = [94, 190];
EEG = pop_reref(EEG, mastoids);

% save the data
EEG = pop_saveset(EEG);