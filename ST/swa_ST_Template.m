% Template script for saw-tooth wave detection
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

% Load the data from EEGLAB
% ^^^^^^^^^^^^^^^^^^^^^^^^^
[Data, Info] = swa_convertFromEEGLAB();
% or if you have previously analysed some data
[Data, Info, ST] = swa_load_previous();

% Get the default parameters
% ^^^^^^^^^^^^^^^^^^^^^^^^^^
Info = swa_getInfoDefaults(Info, 'ST');

% Adjust the parameters as desired here
% e.g. to set the standard deviations for thresholding,
% Info.Parameters.CWT_StdThresh = 3; 

% Find the ST Waves in the Dataset
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
[Data.STRef, Info]  = swa_CalculateReference(Data.Raw, Info);
[Data, Info, ST]    = swa_FindSTRef(Data, Info);
[Data, Info, ST]    = swa_FindSTChannels(Data, Info, ST);
[Info, ST]          = swa_FindSTTravelling(Info, ST);

% Apply Burst Criteria if desired
BurstCriteria = [ST.Burst_BurstId];     
ST(isnan(BurstCriteria)) = [];

% Save the data
% ^^^^^^^^^^^^^
% Replace the data with a file pointer if drive space is a concern
Data.Raw = Info.Recording.dataFile;

% Done! Use the swa_Explorer to visualise the results.
[saveFile, savePath] = uiputfile('*.mat');
save([savePath, saveFile], 'Data', 'Info', 'ST', '-mat');


