%% -- Workflow and Plots for Slow Wave Analysis -- %%

% read the preprocessed data or another swa file

% for eeglab files
[Data, Info] = swa_convertFromEEGLAB();
% or if you have previously analysed some data
[Data, Info, SW] = swa_load_previous();


%% -- Template for envelope method -- %%

% get the default parameters
Info = swa_getInfoDefaults(Info, 'SW', 'envelope');

% change parameters here
% e.g.
Info.Parameters.Ref_AmplitudeCriteria = 'relative';

% run through the 4 wave detection steps
[Data.SWRef, Info]  = swa_CalculateReference (Data.Raw, Info);
[Data, Info, SW]    = swa_FindSWRef (Data, Info);
[Data, Info, SW]    = swa_FindSWChannels (Data, Info, SW);
[Info, SW]          = swa_FindSWTravelling (Info, SW);

% save the data
swa_saveOutput(Data, Info, SW, [], 1, 0)


%% -- Template for Regions Reference -- %%
% set mdc specific defaults
Info = swa_getInfoDefaults(Info, 'SW', 'MDC');

[Data.SWRef, Info]  = swa_CalculateReference(Data.Raw, Info);
[Data, Info, SW]    = swa_FindSWRef(Data, Info);
[Data, Info, SW]    = swa_FindSWChannels(Data, Info, SW);
[Info, SW]          = swa_FindSWTravelling(Info, SW);