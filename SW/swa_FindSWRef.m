function [SW, Info] = swa_FindSWRef(Data, Info, SW)

%% Initialise the SW Structure
if nargin < 3 || isempty(SW)
    SW=struct(...
        'Ref_Down',             [], ...     % index of downward zero crossing
        'Ref_Up',               [], ...     % index of upward zero crossing
        'Ref_PeakId',           [], ...     % index of maximum negativity using Massimini criteria
        'Ref_NegSlope',         [], ...     % maximum of negative slope
        'Ref_PosSlope',         [], ...     % maximum of slope index in the upswing
        'Channels_Active',      [], ...     % List of channels with a slow wave, in temporal order
        'Channels_NegAmp',      [], ...     % Peak negative amplitude in the channels
        'Channels_NegAmpId',    [], ...     % Channel index for the peak negative amplitude
        'Channels_Globality',   [], ...     % Percentage of active channels from total
        'Travelling_Delays',    [], ...     % Delay of negative peak for each channel in samples
        'Travelling_DelayMap',  [], ...     % Interpolated map of the delays
        'Travelling_Streams',   [], ...     % Principle direction of travel
        'Code',                 []);        % Code for the wave (type 1 or type 2)
    
        OSWCount = 0; % counts empty as one... fix!
        SWCount  = 0;
else
        OSWCount = length(SW); % counts empty as one... fix!
        SWCount  = length(SW);    
end

%% Info defaults
if ~isfield(Info.Parameters, 'Ref_NegAmpMin')
    display('Warning: No detection parameters found in Info; using defaults');
    Info.Parameters.Ref_NegAmpMin   = 80;
    Info.Parameters.Ref_ZCLength    = [0.25 1.25];
    Info.Parameters.Ref_SlopeMin    = 0.90;
    Info.Parameters.Ref_Peak2Peak   = 140;
end

%% Get Downward and Upward Zero Crossings (DZC and UZC)
signData    = sign(Data);       % gives the sign of data
slopeData   = [0 diff(Data)];   % gives the differential of data (slope)

% Calculate xth percentile slope
x = sort(slopeData);
slopeThresh = x(round(length(x)*Info.Parameters.Ref_SlopeMin));

DZC = find(diff(signData) == -2); % -2 indicates when the sign goes from 1 to -1
UZC = find(diff(signData) == 2);

% Check for earlier initial UZC than DZC
if DZC(1)>UZC(1)
    UZC(1)=[];
    if length(DZC) ~= length(UZC) % in case the last DZC does not have a corresponding UZC then delete it
            DZC(end)=[];
    end
end

% Check for last DZC with no UZC
if length(DZC)>length(UZC)
    DZC(end) = [];
end

% Test Wavelength
% ```````````````
% Get all the wavelengths
SWLengths = UZC-DZC;
% Too short
BadZC = SWLengths < Info.Parameters.Ref_ZCLength(1)*Info.Recording.sRate;
% Too long
BadZC(  SWLengths > Info.Parameters.Ref_ZCLength(2)*Info.Recording.sRate) = true;
% Eliminate the indices
UZC(BadZC) = [];
DZC(BadZC) = [];

% Calculate Amplitude Threshold Criteria
% ```````````````````````````````````````
if ~isempty(Info.Parameters.Ref_AmpStd)
    MNP  = find(diff(sign(slopeData))==2);  % Maximum Negative Point (trough of the wave)
    StdMor = mad(Data(MNP), 1);             % Returns the absolute deviation from the median (to avoid outliers)
    Info.Parameters.Ref_NegAmpMin = (StdMor*Info.Parameters.Ref_AmpStd)+abs(mean(Data(MNP))); % Overwrite amp threshold
end

% To check differences between next peaks found...
AllPeaks = [SW.Ref_PeakId];

%% Loop through each DZC for criteria
for i = 1:length(DZC)
      
    % Test for negative amplitude
    [NegPeakAmp,NegPeakId] = min(Data(1,DZC(i):UZC(i)));
    if abs(NegPeakAmp) < Info.Parameters.Ref_NegAmpMin
        continue;
    end
    NegPeakId = NegPeakId+DZC(i);
    
    % MDC Test for peak to peak amplitude
    if strcmp(Info.Parameters.Ref_Method,'MDC')
        PosPeakAmp = max(Data(1,UZC(i):UZC(i)+2*Info.Recording.sRate));
        if PosPeakAmp-NegPeakAmp < Info.Parameters.Ref_Peak2Peak
            continue;
        end
    end
    
    % Test for positive slope
    MaxPosSlope = max(slopeData(1,DZC(i):UZC(i)));
    if MaxPosSlope < slopeThresh
        continue;
    end    
    
    % Check if the SW has already been found in another reference channel
    if nargin == 3      
        c = double(AllPeaks > DZC(i)) + double(AllPeaks < UZC(i));
        if max(c) == 2
            continue;
        end
    end
    
    SWCount = SWCount+1;
    
    SW(SWCount).Ref_Down      = DZC(i);    
    SW(SWCount).Ref_Up        = UZC(i);    
    SW(SWCount).Ref_NegSlope  = min(slopeData(1,DZC(i):UZC(i)));
    SW(SWCount).Ref_PosSlope  = MaxPosSlope;
    SW(SWCount).Ref_PeakId    = NegPeakId;     
    
end
if nargin == 3
    fprintf(1, 'Information: %d slow waves added to structure \n', length(SW)-OSWCount);
else
    fprintf(1, 'Information: %d slow waves found in data series \n', length(SW)-OSWCount);
end
