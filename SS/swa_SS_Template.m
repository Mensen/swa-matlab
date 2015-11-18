%% -- Workflow and Plots for Spindle Analysis -- %%
% Basic processing script for the automatic detection of spindles using the swa toolbox...

% Importing Data %
% -------------- %
% if you have scored the data
[fileName, filePath] = uigetfile('*.set');
load(fullfile(filePath, fileName), '-mat');
keep_samples = EEG.swa_scoring.stages == 2;
keep_samples(EEG.swa_scoring.arousals) = false;
EEG = swa_selectStagesEEGLAB(EEG, keep_samples);

% for eeglab files
[Data, Info] = swa_convertFromEEGLAB();

% or if you have previously analysed some data
[Data, Info, SS] = swa_load_previous();

% Check for 'N2' name and call it 'Raw'...
if isfield(Data, 'N2')
    Data.Raw = Data.N2;
    Data = rmfield(Data, 'N2');
end


% Spindle Detection %
% ----------------- %
% get the default settings for spindle detection
Info = swa_getInfoDefaults(Info, 'SS');

% calculate the canonical / reference / prototypical / representative / model / illustrative wave
[Data.SSRef, Info]  = swa_CalculateReference(Data.Raw, Info);
    
% find the spindles in the reference
[Data, Info, SS] = swa_FindSSRef(Data, Info);

% find the waves in all channels
[Data, Info, SS] = swa_FindSSChannels(Data, Info, SS);

% save the data
swa_saveOutput(Data, Info, SS, [], 1, 0)


% Basic Plotting Scripts %
% ---------------------- %
data = Data.SSRef(2, 3601:3900);
time = 1/Info.sRate : 1/Info.sRate : size(data,2)/Info.sRate;
figure('color', 'w', 'position', [50,50, 1000, 500]); 
plot(time, data, 'k', 'linewidth', 2);
set(gca, 'YLim', [-60, 60]);

% Plot wave after detection
% ~~~~~~~~~~~~~~~~~~~~~~~~~
nSS = 120;
win = Info.Recording.sRate * 2;
range =  SS(nSS).Ref_Start - win...
    : SS(nSS).Ref_End + win;
ref_data = Data.SSRef(SS(nSS).Ref_Region(1), range);
pow_data = Data.CWT{1}(SS(nSS).Ref_Region(1), range + 10);

time = linspace(-win/Info.Recording.sRate,...
    + win/Info.Recording.sRate, length(range));

figure('color', 'w', 'position', [50, 50, 1000, 500]);
axes('nextPlot', 'add');
plot(time, ref_data, 'color', 'b', 'linewidth', 1);
% plot(time, pow_data.^0.5 * 4, 'color', 'r', 'linewidth', 3);

set(gca, 'YLim', [-60, 60]);


% plot the three reference waves
nSS = 18;
win = Info.Recording.sRate * 1.5;
range =  SS(nSS).Ref_Start-win:SS(nSS).Ref_End+win;
time = 1/Info.Recording.sRate:1/Info.Recording.sRate:size(ref_data,2)/Info.Recording.sRate;
figure('color', 'w', 'position', [50,50, 1000, 500]); 
hold all;
plot(time, Data.SSRef(1, range)+50, 'color', 'g',  'linewidth', 2);
plot(time, Data.SSRef(2, range),    'color', 'b',  'linewidth', 2);
plot(time, Data.SSRef(1, range)-50, 'color', 'r',  'linewidth', 2);