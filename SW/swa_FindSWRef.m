function [Data, Info, SW] = swa_FindSWRef(Data, Info, SW)

% check inputs
if nargin < 2
    error('Error: Must have variables Data and Info as inputs');
end

% check for appropriate parameters
if ~isfield(Info.Parameters, 'Ref_Method')
    fprintf(1, 'Error: No detection parameters found in the ''Info'' structure');
    return;
end

% Initialise the SW Structure
if nargin < 3 || isempty(SW)
    SW = struct(...
        'Ref_Region',           [], ...     % region the wave was found in
        'Ref_DownInd',          [], ...     % index of downward zero crossing or previous maxima if using MNP
        'Ref_PeakInd',          [], ...     % index of maximum negativity
        'Ref_UpInd',            [], ...     % index of upward zero crossing or subsequent maxima
        'Ref_PeakAmp',          [], ...     % negative peak amplitude
        'Ref_P2PAmp',           [], ...     % only used as a criteria for the non-envelope references
        'Ref_NegSlope',         [], ...     % maximum of negative slope
        'Ref_PosSlope',         [], ...     % maximum of slope index in the upswing
        'Channels_Active',      [], ...     % List of channels with a slow wave, in temporal order
        'Channels_NegAmp',      [], ...     % Peak negative amplitude in the channels
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

% number of reference waves
number_ref_waves = size(Data.SWRef,1);

% initialise loop variables
switch Info.Parameters.Ref_AmplitudeCriteria
    case 'relative'
        Info.Parameters.Ref_AmplitudeAbsolute = zeros(number_ref_waves, 1);
    case 'absolute'
        Info.Parameters.Ref_AmplitudeRelative = zeros(number_ref_waves, 1);
end
Info.Recording.Data_Deviation = zeros(number_ref_waves, 1);

% check for sufficient absolute thresholds for multi-references
if strcmp(Info.Parameters.Ref_AmplitudeCriteria, 'absolute')
    if length(Info.Parameters.Ref_AmplitudeAbsolute) < number_ref_waves
        Info.Parameters.Ref_AmplitudeAbsolute = repmat(Info.Parameters.Ref_AmplitudeAbsolute(1), [number_ref_waves, 1]);
    end
end


% loop for each reference
for ref_wave = 1:number_ref_waves

    % keep track of previous wave count
    if ref_wave > 1
        OSWCount = length(SW);
    end

    % calculate the slope of the data
    slopeData   = [0 diff(Data.SWRef(ref_wave, :))];
    
    % get the local minima and maxima (and eliminate small notches)
    [MNP, MPP] = swa_get_peaks(slopeData, Info, 1);
    
    % eliminate the MNP in non used stages
    if ~isempty(Info.Parameters.Ref_UseStages)
        selected_peaks = ismember(Data.sleep_stages(MNP), ...
            Info.Parameters.Ref_UseStages);
        
        % eliminate peaks outside stages of interest
        relevant_MNP = MNP(~selected_peaks);
    else
        selected_peaks = true(length(MNP), 1);
        relevant_MNP = MNP;
    end
    
    % calculate amplitude threshold criteria
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % absolute deviation from the median (to avoid outliers)
    Info.Recording.Data_Deviation(ref_wave) = ...
        mad(Data.SWRef(ref_wave, relevant_MNP), 1);
    
    switch Info.Parameters.Ref_AmplitudeCriteria
        case 'relative'
            % calculate new threshold
            Info.Parameters.Ref_AmplitudeAbsolute(ref_wave) = ...
                (Info.Recording.Data_Deviation(ref_wave) * Info.Parameters.Ref_AmplitudeRelative)...
                + abs(median(Data.SWRef(ref_wave, relevant_MNP)));
            fprintf(1, 'Calculation: Amplitude threshold set to %.1fuV for canonical wave %i\n',...
                Info.Parameters.Ref_AmplitudeAbsolute(ref_wave), ref_wave);
            
        case 'absolute'
            % calculate deviations from mean activity
            Info.Parameters.Ref_AmplitudeRelative(ref_wave) =  (Info.Parameters.Ref_AmplitudeAbsolute(ref_wave)...
                - abs(median(Data.SWRef(ref_wave, relevant_MNP)))) / Info.Recording.Data_Deviation(ref_wave);
            fprintf(1, 'Information: Threshold is %.1f deviations from median activity \n', Info.Parameters.Ref_AmplitudeRelative(ref_wave));
    end
    
    % check for specified peak to peak criteria
    % TODO: peak to peak set to 1.75, export parameter
    if isempty(Info.Parameters.Ref_Peak2Peak)
        Info.Parameters.Ref_Peak2Peak = ...
            abs(Info.Parameters.Ref_AmplitudeAbsolute(ref_wave)) * 1.75;
    end
    
    % switch inspection methods
    switch Info.Parameters.Ref_InspectionPoint
        % Peak detection method
        % ~~~~~~~~~~~~~~~~~~~~~
        case 'MNP'
            % Define badWaves
            badWaves = false(1, length(MNP));
            
            % eliminate waves in non specified stages
            badWaves(~selected_peaks) = true;

            % Wavelength criteria
            % ```````````````````
            % MPP->MPP length
            MPP2MPPlength = diff(MPP);
            badWaves    ( MPP2MPPlength < Info.Parameters.Ref_WaveLength(1)*Info.Recording.sRate...
                        | MPP2MPPlength > Info.Parameters.Ref_WaveLength(2)*Info.Recording.sRate)...
                        = true;
            % MNP->MPP length
            % must be at least half of the specified wavelength
            MNP2MPPlength = MPP(2:end)-MNP;
            badWaves    ( MNP2MPPlength < Info.Parameters.Ref_WaveLength(1)*Info.Recording.sRate/2 ...
                        | MNP2MPPlength > Info.Parameters.Ref_WaveLength(2)*Info.Recording.sRate/2) ...
                        = true;

            % Amplitude criteria
            % ```````````````````
            % mark lower than threshold amps and larger than 220uV (artifacts)
            badWaves    ( Data.SWRef(ref_wave, MNP) > -Info.Parameters.Ref_AmplitudeAbsolute(ref_wave)...
                | Data.SWRef(ref_wave, MNP) < -220)...
                = true;

            % peak to peak amplitude
            p2p = Data.SWRef(ref_wave, MPP(2:end)) - Data.SWRef(ref_wave, MNP);
            % peaks should not be calculated for envelope references
            if ~strcmp(lower(Info.Parameters.Ref_Method), 'envelope')
                badWaves ( p2p < Info.Parameters.Ref_Peak2Peak)...
                    = true;
            end

            % Get all the MNP from a previous reference
            % this will return empty for the first reference
            AllPeaks = [SW.Ref_PeakInd];
            
            % Loop through each MNP to save criteria
            for n = find(~badWaves)
                
                % Check if the SW has already been found in another reference channel
                if ref_wave > 1
                    [c, SWid] = max(double(AllPeaks > MPP(n)) + double(AllPeaks < MPP(n+1)));
                    if c == 2
                        % Check which region has the bigger P2P wave...
                        if Data.SWRef(ref_wave, MNP(n)) < SW(SWid).Ref_PeakAmp
                            % If the new region does then overwrite previous data with larger reference
                            SW(SWid).Ref_Region    = [ref_wave, SW(SWid).Ref_Region];
                            SW(SWid).Ref_DownInd   = MPP(n);
                            SW(SWid).Ref_PeakInd   = MNP(n);
                            SW(SWid).Ref_UpInd     = MPP(n+1);
                            SW(SWid).Ref_PeakAmp   = Data.SWRef(ref_wave, MNP(n));
                            SW(SWid).Ref_P2PAmp    = p2p(n);
                            SW(SWid).Ref_NegSlope  = min(slopeData(1,MPP(n):MPP(n+1)));
                            SW(SWid).Ref_PosSlope  = max(slopeData(1,MPP(n):MPP(n+1)));
                        else
                            % Just add the reference region
                            SW(SWid).Ref_Region(end+1) = ref_wave;
                        end
                        
                        continue;
                    end
                end
                
                % Keep count of the waves found
                SWCount = SWCount+1;
                
                % Save the values
                SW(SWCount).Ref_Region    = ref_wave;
                SW(SWCount).Ref_DownInd   = MPP(n);                
                SW(SWCount).Ref_PeakInd   = MNP(n);
                SW(SWCount).Ref_UpInd     = MPP(n+1);
                SW(SWCount).Ref_PeakAmp   = Data.SWRef(ref_wave, MNP(n));
                SW(SWCount).Ref_P2PAmp    = p2p(n);
                SW(SWCount).Ref_NegSlope  = min(slopeData(1,MPP(n):MPP(n+1)));
                SW(SWCount).Ref_PosSlope  = max(slopeData(1,MPP(n):MPP(n+1)));
                
            end
            
            
        % Zero crossing detection method
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        case 'ZC'
            % Get Downward and Upward Zero Crossings (DZC and UZC)
            signData    = sign(Data.SWRef(ref_wave,:));
            % fix rare issue where slope is exactly 0
            signData(signData == 0) = 1;
            % -2 indicates when the sign goes from 1 to -1
            DZC = find(diff(signData) < 0); 
            UZC = find(diff(signData) > 0);
            
            % make the UZC the sample after the zero-crossing
            UZC = UZC + 1;
            
            % Calculate xth percentile slope
            x = sort(slopeData);
            slopeThresh = prctile(x(x>0), Info.Parameters.Ref_SlopeMin * 100);
            
            % Check for earlier initial UZC than DZC
            if DZC(1) >= UZC(1)
                UZC(1)=[];
                % in case the last DZC does not have a corresponding UZC then delete it
                if length(DZC) ~= length(UZC)
                    DZC(end)=[];
                end
            end
            
            % Check for last DZC with no UZC
            if length(DZC)>length(UZC)
                DZC(end) = [];
            end
            
            % if DZC is in non_specified stage then skip
            if ~isempty(Info.Parameters.Ref_UseStages)
                selected_peaks = ismember(Data.sleep_stages(DZC), ...
                    Info.Parameters.Ref_UseStages);
                
                % remove crossings in irrelevant stages
                DZC(~selected_peaks) = [];
                UZC(~selected_peaks) = [];
            end
            
            % Test Wavelength
            % ```````````````
            % Get all the wavelengths
            SWLengths = UZC-DZC;
            % Too short
            BadZC = SWLengths < Info.Parameters.Ref_WaveLength(1) * Info.Recording.sRate;
            % Too long
            BadZC(  SWLengths > Info.Parameters.Ref_WaveLength(2) * Info.Recording.sRate) = true;
            % Eliminate the indices
            UZC(BadZC) = [];
            DZC(BadZC) = [];
            
            % To check differences between next peaks found...
            AllPeaks = [SW.Ref_PeakInd];
            
            % Loop through each DZC for criteria
            for n = 1:length(DZC)               
                
                % Test for negative amplitude
                % ```````````````````````````````
                [NegPeakAmp, NegPeakId] = min(Data.SWRef(ref_wave, DZC(n):UZC(n)));
                if NegPeakAmp > -Info.Parameters.Ref_AmplitudeAbsolute(ref_wave) || ...
                    NegPeakAmp < -Info.Parameters.Ref_AmplitudeMax
                    continue;
                end
                
                % adjust negative peak indice on DZ
                NegPeakId = NegPeakId + DZC(n) - 1;
                
                % Test for peak to peak amplitude
                % ```````````````````````````````
                sample_range = UZC(n):UZC(n) + 1 * Info.Recording.sRate;
                sample_range(sample_range > size(Data.SWRef, 2)) = []; % adjust in case it hits the end sample
                
                % calculate the positive peak after the zero crossing
                PosPeakAmp = max(Data.SWRef(ref_wave, sample_range));
                if strcmp(Info.Parameters.Ref_Method, {'diamond', 'square'})
                    if PosPeakAmp - NegPeakAmp < Info.Parameters.Ref_Peak2Peak
                        continue;
                    end
                end
                
                % Test for positive slope
                % ```````````````````````````````
                MaxPosSlope = max(slopeData (1, DZC(n) : UZC(n)));
                if MaxPosSlope < slopeThresh
                    continue;
                end
                                   
                % Check if the SW has already been found in another reference channel
                % ```````````````````````````````
                if ref_wave > 1
                    [c, SWid] = max(double(AllPeaks > DZC(n)) + double(AllPeaks < UZC(n)));
                    if c == 2
                        % Check which region has the bigger P2P wave...
                        % TODO: slow wave down should be earliest, and up
                        % the latest
                        if Data.SWRef(ref_wave, NegPeakId) < SW(SWid).Ref_PeakAmp
                            % If the new region does then overwrite previous data with larger reference
                            SW(SWid).Ref_Region    = [ref_wave, SW(SWid).Ref_Region];
                            SW(SWid).Ref_DownInd   = DZC(n);
                            SW(SWid).Ref_PeakInd   = NegPeakId;
                            SW(SWid).Ref_UpInd     = UZC(n);
                            SW(SWid).Ref_PeakAmp   = Data.SWRef(ref_wave, NegPeakId);
                            SW(SWid).Ref_P2PAmp    = PosPeakAmp-NegPeakAmp;
                            SW(SWid).Ref_NegSlope  = min(slopeData(1,DZC(n):UZC(n)));
                            SW(SWid).Ref_PosSlope  = MaxPosSlope;
                            
                        else
                            % Just add the reference region
                            SW(SWid).Ref_Region(end+1) = ref_wave;
                            
                        end
                        
                        continue;
                    end
                end
                
                % Keep count of the waves found
                SWCount = SWCount+1;
                
                % Save the values
                SW(SWCount).Ref_Region    = ref_wave;
                SW(SWCount).Ref_DownInd   = DZC(n);                
                SW(SWCount).Ref_PeakInd   = NegPeakId;
                SW(SWCount).Ref_UpInd     = UZC(n);
                SW(SWCount).Ref_PeakAmp   = Data.SWRef(ref_wave, NegPeakId);
                SW(SWCount).Ref_P2PAmp    = PosPeakAmp - NegPeakAmp;
                SW(SWCount).Ref_NegSlope  = min(slopeData(1,DZC(n):UZC(n)));
                SW(SWCount).Ref_PosSlope  = MaxPosSlope;
                               
            end
            
        otherwise
            fprintf(1, 'Error: Unrecognised detection method');
            return;
    end
    
    if ref_wave > 1
        fprintf(1, 'Information: %d slow waves added to structure \n', length(SW)-OSWCount);
    else
        fprintf(1, 'Information: %d slow waves found in data series \n', length(SW)-OSWCount);
    end   
end

% sort the waves in temporal order
[~, sorted_index] = sort([SW.Ref_DownInd]);
SW = SW(sorted_index);

% delete the waves found in none-specified sleep stages
if ~isempty(Info.Parameters.Ref_UseStages) && isfield(Data, 'sleep_stages')
   
   % get the list of samples from exluded stages
   excluded_samples = find(~ismember(Data.sleep_stages,  Info.Parameters.Ref_UseStages));
   % get the list of SWs that are found in excluded stages
   bad_waves = ismember([SW.Ref_PeakInd], excluded_samples);
   % remove those waves
   SW(bad_waves) = [];
   
   % give a message about the number removed
   if sum(bad_waves) > 0;
       fprintf(1, 'Information: %i waves were found in non-specified stages and removed\n', sum(bad_waves)); 
   end
   
elseif ~isempty(Info.Parameters.Ref_UseStages) && ~isfield(Data, 'sleep_stages')
    fprintf(1, 'Warning: stages were specified in parameters but no scoring information was found\n');
end