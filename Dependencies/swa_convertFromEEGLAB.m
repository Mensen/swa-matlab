function [Data, Info] = swa_convertFromEEGLAB(fileName)

if nargin < 1
    [fileName, filePath] = uigetfile('*.set');
end
load([filePath, fileName], '-mat');


Info.Recording.dataFile   = EEG.data;
Info.Recording.dataDim    =[EEG.nbchan, EEG.pnts];
Info.Recording.sRate      = EEG.srate;
Info.Recording.reference  = EEG.ref;
Info.Electrodes           = EEG.chanlocs;

fid = fopen(Info.Recording.dataFile);
Data.Raw = fread(fid, Info.Recording.dataDim, 'single');
fclose(fid);