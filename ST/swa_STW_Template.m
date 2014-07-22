%% swa_STW_Template

%% -- Data structure -- %%

% Data
% the variable 'Data' should be a structure containing the field 'REM' which contains a 2D matrix
% of channels v samples (e.g. size(Data.REM) = [256, 2000]). If importing data from EEGLAB just load
% the .set file (>> EEG = pop_loadset();) then type >> Data.Raw = EEG.data

% Info
% the variable 'Info', should already contain two fields, '.sRate' and '.Electrodes'. These can also
% be taken directly from the EEGLAB file using >> Info.sRate = EEG.srate; and >> Info.Electrodes = 
% EEG.chanlocs;

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

[Data.STRef, Info]  = swa_CalculateReference(Data.REM, Info);

%% New CWT Method
% CWT Parameters
Info.Parameters.CWT_hPass           = 2;
Info.Parameters.CWT_lPass           = 5;

Info.Parameters.CWT_StdThresh       = 1.75;    % Explore defaults
Info.Parameters.CWT_AmpThresh       = [];
Info.Parameters.CWT_ThetaAlpha      = 1.2;
Info.Parameters.Burst_Length        = 1;       % Maximum time between waves in seconds

[Data, Info, ST] = swa_FindSTRef(Data, Info);

%% Apply Burst as Criteri[Info, ST] = swa_FindSTTravelling(Info, ST);
% a (Probably best to lower other criteria in order to capture all waves in burst

BurstCriteria = [ST.Burst_BurstId];     
ST(isnan(BurstCriteria)) = [];            % Delete all nan BurstIds

%% For rest of channels
Info.Parameters.Channels_WinSize = 0.060; % in seconds

%% Find ST in All Channels
[Data, Info, ST] = swa_FindSTChannels(Data, Info, ST);

%% Find Streams
Info.Parameters.Travelling_GS       = 40; % Gridsize for delay map
Info.Parameters.Travelling_MinDelay = 20; % minimum travel time in ms

[Info, ST] = swa_FindSTTravelling(Info, ST);

%% -- Reference Parameters for Envelope Method -- *old* %%
% Need extra parameters for envelope and filtering enabled...
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
