function [Data, Info] = swa_convertFromEEGLAB(fileName)

if nargin < 1
    [fileName, filePath] = uigetfile('*.set');
    load([filePath, fileName], '-mat');
end

Info.dataFile   = EEG.data;
Info.dataDim    =[EEG.nbchan, EEG.pnts];
Info.sRate      = EEG.srate;
Info.Electrodes = EEG.chanlocs;

fid = fopen(Info.dataFile);
Data.Raw = fread(fid, Info.dataDim, 'single');
fclose(fid);