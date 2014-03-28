%% swa_STW_Template

%% Load EEG
[dataFile, dataPath] = uigetfile('*.set', 'Please Select Data File');
EEG = pop_loadset([dataPath, dataFile]);

% Select only a certain data range
% EEG = pop_select(EEG, 'point', [233875+308876, 233875+308876+330785]);
% EEG = eeg_checkset( EEG );

% For Francesca's Dream Data
EEG.data(257,:)=[];
EEG = eeg_checkset( EEG );

% Load Channel Information (And put Cz reference separate)
EEG = pop_chanedit( EEG, 'load',{'C:\MATLAB\Toolboxes\fieldtrip-20130929\template\electrode\GSN-HydroCel-257.sfp' 'filetype' 'autodetect'},'delete',1,'delete',1,'delete',1,'changefield',{257 'datachan' 0});
EEG = eeg_checkset( EEG );

% Resample to 150Hz
EEG = pop_resample( EEG, 150);
EEG = eeg_checkset( EEG );

% Filter the data
% EEG = pop_eegfiltnew(EEG, 0.3, 30); 
% EEG = eeg_checkset( EEG );

% Average reference
% EEG = pop_reref( EEG, [],'refloc',EEG.chaninfo.nodatchans(1));
% EEG = eeg_checkset( EEG );

% Mastoid reference [55/98 A1/A2 for 129... // 90/190 for 256]
% EEG = pop_reref( EEG, [90 190] ,'refloc', EEG.chaninfo.nodatchans(1)); % Bring back Cz from the nodatachans
% EEG = pop_reref( EEG, [55 98] ,'refloc', EEG.chaninfo.nodatchans(1)); % Bring back Cz from the nodatachans
% EEG = pop_reref( EEG, [90 190]); % Bring back Cz from the nodatachans
EEG = pop_reref( EEG, [55 98]); % Bring back Cz from the nodatachans

% EEG = eeg_checkset( EEG );

Info.EEG_Filename = dataFile;
Info.Electrodes = EEG.chanlocs;
Info.sRate = EEG.srate;
Info.Reference = 'Mastoid';
% Info.Reference = 'Average';
Data.REM = double(EEG.data);

%% -- Setting Parameters -- %%

Info.Parameters.Ref_Method      = [];  % 'Envelope'/'MDC'/'Central'/'Midline'
Info.Parameters.Ref_UseInside   = [];  % true/false

Info.Parameters.Filter_Apply    = [];  % true/false 
Info.Parameters.Filter_Method   = [];  % 'Chebyshev'/'Buttersworth'
Info.Parameters.Filter_hPass    = [];
Info.Parameters.Filter_lPass    = [];
Info.Parameters.Filter_order    = [];

Info.Parameters.CWT_hPass       = [];
Info.Parameters.CWT_lPass       = [];
Info.Parameters.CWT_StdThresh   = [];   % Number of standard deviations from the mean
Info.Parameters.CWT_AmpThresh   = [];   % If left empty the StdThresh is used to calculate this
Info.Parameters.CWT_ThetaAlpha  = [];   % Theta/Alpha power

Info.Parameters.Burst_Length    = [];

Info.Parameters.Channels_WinSize    = []; % in seconds
Info.Parameters.Channels_CorrThresh = [];

Info.Parameters.Travelling_GS       = [];
Info.Parameters.Travelling_MinDelay = [];

%% -- Calculating Waves -- %%
%% Reference Parameters
Info.Parameters.Ref_Method      = 'Midline'; 
Info.Parameters.Filter_Apply    = false; % No filter needed for CWT method...
%
[Data.STRef, Info]  = swa_CalculateReference(Data.REM, Info);

%% New CWT Method
% CWT Parameters
Info.Parameters.CWT_hPass           = 2;
Info.Parameters.CWT_lPass           = 5;

Info.Parameters.CWT_StdThresh       = 1.75;    % Explore defaults
Info.Parameters.CWT_AmpThresh       = [];
Info.Parameters.CWT_ThetaAlpha      = 1.2;
Info.Parameters.Burst_Length        = 1;       % Maximum time between waves in seconds
% Info.Parameters.CWT.Peak2PeakAmp     = 40; %If left out will calculate peak to peak based off stdThresh

[Data, Info, ST] = swa_FindSTRef(Data, Info);

%% Apply Burst as Criteria (Probably best to lower other criteria in order to capture all waves in burst

BurstCriteria = [ST.Burst_BurstId];     
ST(isnan(BurstCriteria))=[];            % Delete all nan BurstIds

%% For rest of channels
Info.Parameters.Channels_WinSize = 0.060; % in seconds
% Info.Parameters.Channels_CorrThresh = 0.85;

%% Find ST in All Channels
[Data, Info, ST] = swa_FindSTChannels(Data, Info, ST);

%% Find Streams
Info.Parameters.Travelling_GS       = 40; % Gridsize for delay map
Info.Parameters.Travelling_MinDelay = 20; % minimum travel time in ms

[Info, ST] = swa_FindSTTravelling(Info, ST);

%% Reference Parameters
Info.Parameters.Method = 'Envelope'; 
% Info.Method = 'Central'; 
Info.Parameters.Ref_UseInside = true;

% Filter Parameters
Info.Parameters.Filter.Apply   = true; % No filter needed for CWT method...
Info.Parameters.Filter.Method  = 'Chebyshev';
Info.Parameters.Filter.hPass   = 4;
Info.Parameters.Filter.lPass   = 7;
Info.Parameters.Filter.order   = 2;


% For reference calculation
Info.Parameters.NegPeak = 6;
Info.Parameters.NegLength = [0.1 0.6];
Info.Parameters.NegSlopePerc = 0.90;
Info.Parameters.Peak2Peak = 15;

Info.Parameters.BurstCheck = true;
Info.Parameters.BurstNumber = 2;

%% Find ST in Reference Channel
[ST, Info] = swa_FindSTRef(Data.STRef, Info);

%% Plotting Functions

% Plot the original and reference data
Start = 2000;
Length = 500;
% All the data...
figure('Color', 'w');
plot(Data.REM(:,Start:Start+Length-1)','Color', [0.5 0.5 0.5], 'linewidth', 0.5) % all channels in grey
hold on;
plot(Data.REM(257,Start:Start+Length-1)','Color', 'b', 'linewidth', 3) % all channels in grey
plot(Data.STRef(:,Start:Start+Length-1)','Color', 'r', 'linewidth', 3) % reference in blue

% Plot a STW
nST = 6;
win = round(0.5*Info.sRate);
if ST(nST).Ref_NegativePeak < win
    srData = Data.STRef(ST(nST).Ref_Region(1),1:ST(nST).Ref_NegativePeak+win);
    cwtData = Data.CWT{1}(ST(nST).Ref_Region(1),1:ST(nST).Ref_NegativePeak+win);
else
    srData = Data.STRef(ST(nST).Ref_Region(2),ST(nST).Ref_NegativePeak-win:ST(nST).Ref_NegativePeak+win);
    cwtData = Data.CWT{1}(ST(nST).Ref_Region(2),ST(nST).Ref_NegativePeak-win:ST(nST).Ref_NegativePeak+win);
end

figure('color', 'w'); plot(srData, 'Linewidth', 2, 'color', 'r'); hold on; plot(cwtData, 'color', 'b', 'linewidth', 2);
