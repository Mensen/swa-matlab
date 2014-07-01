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

% Check for 'N2' name and call it 'Raw'...
if isfield(Data, 'N2')
    Data.Raw = Data.N2;
    Data = rmfield(Data, 'N2');
end

%% -- Setting Parameters -- %%

Info.Parameters.Ref_Method      = [];  % 'Envelope'/'MDC'/'Central'/'Midline'
Info.Parameters.Ref_UseInside   = [];  % true/false
Info.Parameters.Ref_MinLength   = [];
Info.Parameters.Ref_MinWaves    = [];

Info.Parameters.Filter_Apply    = [];  % true/false 
Info.Parameters.Filter_Method   = [];  % 'Chebyshev'/'Buttersworth'
Info.Parameters.Filter_hPass    = [];
Info.Parameters.Filter_lPass    = [];
Info.Parameters.Filter_order    = [];

Info.Parameters.CWT_hPass       = [];
Info.Parameters.CWT_lPass       = [];
Info.Parameters.CWT_StdThresh   = [];   % Number of standard deviations from the mean
Info.Parameters.CWT_AmpThresh   = [];   % If left empty the StdThresh is used to calculate this

Info.Parameters.Channels_WinSize        = []; % in seconds
Info.Parameters.Channels_ThreshFactor   = []; % percent of reference threshold for channel detection

Info.Parameters.Travelling_GS       = [];
Info.Parameters.Travelling_MinDelay = [];

%% -- Calculating Waves -- %%
%% Reference Parameters
Info.Parameters.Ref_Method      = 'Midline'; 
Info.Parameters.Filter_Apply    = false; % No filter needed for CWT method...

[Data.SSRef, Info]  = swa_CalculateReference(Data.Raw, Info);

%% CWT Method
% CWT Parameters

    Info.Parameters.CWT_hPass(1)    = 11.5;
    Info.Parameters.CWT_lPass(1)    = 14;
    Info.Parameters.CWT_hPass(2)    = 14;
    Info.Parameters.CWT_lPass(2)    = 16.5;
    
    Info.Parameters.CWT_StdThresh   = 8;
    Info.Parameters.Ref_MinLength   = 0.3;       % Minimum spindle duration
    Info.Parameters.Ref_MinWaves    = 3;
    
    Info.Parameters.CWT_AmpThresh   = [];
    
[Data, Info, SS] = swa_FindSSRef(Data, Info);

%% For rest of channels
Info.Parameters.Channels_WinSize        = 0.150; % in seconds
Info.Parameters.Channels_ThreshFactor   = 0.75;
Info.Parameters.Travelling_GS           = 40; % Gridsize for delay map

%% Find SS in All Channels
[Data, Info, SS] = swa_FindSSChannels(Data, Info, SS);

%% Find Streams
% Info.Parameters.Travelling_MinDelay = 20; % minimum travel time in ms
% 
% [Info, SS] = swa_FindSSTravelling(Info, SS);

%% Plotting
% data = Data.SSRef(2, 3601:3900);
% time = 1/Info.sRate:1/Info.sRate:size(data,2)/Info.sRate;
% figure('color', 'w', 'position', [50,50, 1000, 500]); 
% plot(time, data, 'k', 'linewidth', 2);
% set(gca, 'YLim', [-60, 60]);


% Plot wave after detection
% ~~~~~~~~~~~~~~~~~~~~~~~~~
nSS = 30;
win = Info.sRate * 1.5;
range =  SS(nSS).Ref_Start-win:SS(nSS).Ref_End+win;
ref_data = Data.SSRef(SS(nSS).Ref_Region(1), range);
% raw_data = Data.Raw(SS(nSS).Channels_Active, range);
pow_data = Data.CWT{1}(SS(nSS).Ref_Region(1), range+10);

cwt_data = cwtData(:, range);
time = 1/Info.sRate:1/Info.sRate:size(ref_data,2)/Info.sRate;

figure('color', 'w', 'position', [50,50, 1000, 500]); 
% Plot active channels if they've been calculated
hold all;
% plot(time, cwt_data*2, 'color', [.5 .5 .5], 'linewidth', 1);
% plot(time, raw_data, 'color', [.5 .5 .5], 'linewidth', 0.5);
plot(time, ref_data, 'color', 'b', 'linewidth', 1);
plot(time, pow_data.^0.5*4, 'color', 'r', 'linewidth', 3);

set(gca, 'YLim', [-60, 60]);


% plot the three reference waves
nSS = 18;
win = Info.sRate * 1.5;
range =  SS(nSS).Ref_Start-win:SS(nSS).Ref_End+win;
time = 1/Info.sRate:1/Info.sRate:size(ref_data,2)/Info.sRate;
figure('color', 'w', 'position', [50,50, 1000, 500]); 
hold all;
plot(time, Data.SSRef(1, range)+50, 'color', 'g',  'linewidth', 2);
plot(time, Data.SSRef(2, range),    'color', 'b',  'linewidth', 2);
plot(time, Data.SSRef(1, range)-50, 'color', 'r',  'linewidth', 2);