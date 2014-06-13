%% swa_SS_Template
% Basic processing script for the automatic detection of spindles using the
% swa toolbox...

%% -- Data structure -- %%
% Data
% ~~~~
% the variable 'Data' should be a structure containing the field 'Raw' which contains a 2D matrix
% of channels v samples (e.g. size(Data.Raw) = [256, 2000]). If importing data from EEGLAB just load
% the .set file (>> EEG = pop_loadset();) then type >> Data.Raw = EEG.data

% Info
% ~~~~
% the variable 'Info', should already contain two fields, '.sRate' and '.Electrodes'. These can also
% be taken directly from the EEGLAB file using >> Info.sRate = EEG.srate; and >> Info.Electrodes = 
% EEG.chanlocs;

%% -- Setting Parameters -- %%

Info.Parameters.Ref_Method      = [];  % 'Envelope'/'MDC'/'Central'/'Midline'
Info.Parameters.Ref_UseInside   = [];  % true/false
Info.Parameters.Ref_MinLength   = [];

Info.Parameters.Filter_Apply    = [];  % true/false 
Info.Parameters.Filter_Method   = [];  % 'Chebyshev'/'Buttersworth'
Info.Parameters.Filter_hPass    = [];
Info.Parameters.Filter_lPass    = [];
Info.Parameters.Filter_order    = [];

Info.Parameters.CWT_hPass       = [];
Info.Parameters.CWT_lPass       = [];
Info.Parameters.CWT_StdThresh   = [];   % Number of standard deviations from the mean
Info.Parameters.CWT_AmpThresh   = [];   % If left empty the StdThresh is used to calculate this

Info.Parameters.Channels_WinSize    = []; % in seconds
Info.Parameters.Channels_CorrThresh = [];

Info.Parameters.Travelling_GS       = [];
Info.Parameters.Travelling_MinDelay = [];

%% -- Calculating Waves -- %%
%% Reference Parameters
Info.Parameters.Ref_Method      = 'Midline'; 
Info.Parameters.Filter_Apply    = false; % No filter needed for CWT method...

[Data.SSRef, Info]  = swa_CalculateReference(Data.Raw, Info);

%% New CWT Method
% CWT Parameters

    Info.Parameters.CWT_hPass(1)    = 11;
    Info.Parameters.CWT_lPass(1)    = 13.5;
    Info.Parameters.CWT_hPass(2)    = 13.5;
    Info.Parameters.CWT_lPass(2)    = 16;
    Info.Parameters.CWT_StdThresh   = 4;

    Info.Parameters.CWT_AmpThresh   = [];
    Info.Parameters.Ref_MinLength   = 0.3;       % Minimum spindle duration
    
[Data, Info, SS] = swa_FindSSRef(Data, Info);

%% For rest of channels
Info.Parameters.Channels_WinSize = 0.100; % in seconds
Info.Parameters.Channels_CorrThresh = 0.9;

%% Find SS in All Channels
[Data, Info, SS] = swa_FindSSChannels(Data, Info, SS);

%% Find Streams
% Info.Parameters.Travelling_GS       = 40; % Gridsize for delay map
% Info.Parameters.Travelling_MinDelay = 20; % minimum travel time in ms
% 
% [Info, SS] = swa_FindSSTravelling(Info, SS);

%% Plotting
% data = Data.SSRef(2, 3601:3900);
% time = 1/Info.sRate:1/Info.sRate:size(data,2)/Info.sRate;
% figure('color', 'w', 'position', [50,50, 1000, 500]); 
% plot(time, data, 'k', 'linewidth', 2);
% set(gca, 'YLim', [-60, 60]);

