function [Data, Info] = swa_convertFromEEGLAB(fileName, filePath)

if nargin < 1
    [fileName, filePath] = uigetfile('*.set');
end
fprintf(1, 'loading set file: %s...', fileName);
load(fullfile(filePath, fileName), '-mat');
fprintf(1, 'done \n');

Info.Recording.dataFile   = EEG.data;
Info.Recording.dataDim    =[EEG.nbchan, EEG.pnts];
Info.Recording.sRate      = EEG.srate;
Info.Recording.reference  = EEG.ref;
Info.Electrodes           = EEG.chanlocs;

fprintf(1, 'loading data file: %s...', fileName);
fid = fopen(fullfile(filePath, Info.Recording.dataFile));
Data.Raw = fread(fid, Info.Recording.dataDim, 'single');
fclose(fid);
fprintf(1, 'done \n');
