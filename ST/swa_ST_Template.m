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
swa_saveOutput(Data, Info, ST, [], 1, 0)
