% script to select stages from eeglab data
% ´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´
% input
% load('C50_ds.set', '-mat')
% keepSamples = EEG.swa_scoring.stages == 2;
% keepSamples(EEG.swa_scoring.arousals) = false;


function EEG = swa_selectStagesEEGLAB(EEG, samples, saveFile)
% check that samples is a logical array
if ~islogical(samples)
    fprintf(1, 'Error: second input should be a logical array');
end

% create the memory map to the data
tmp = memmapfile(EEG.data, 'Format', {'single', [EEG.nbchan EEG.pnts EEG.trials], 'eegData'});
% select the desired samples for the memory mapped data
newData = tmp.Data.eegData(:, samples);

% ask for where to save the file
if nargin < 3
    [saveFile, savePath] = uiputfile('*.set');
end

% adjust the EEG data
EEG.times(~samples)     = [];
EEG.pnts                = size(newData, 2);
EEG                     = eeg_checkset(EEG);

% adjust the dataset name
EEG.data = saveFile; 
EEG.data(end-3: end)    = []; 
EEG.data = [EEG.data, '.fdt'];

% save the EEG struct
save(saveFile, 'EEG', '-mat');

% write the new data file
fileID = fopen(EEG.data,'w');
fwrite(fileID, newData,'single');
fclose(fileID);