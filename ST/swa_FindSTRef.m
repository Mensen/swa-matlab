function [Data, Info, ST] = swa_FindSTRef(Data, Info)
% Version 2: Using Continuous Wavelet Transform

%% Initialise the ST Structure
ST = struct(...
    'CWT_Start',                [],...
    'CWT_End',                  [],...
    'CWT_NegativePeak',         [],...
    'CWT_PeakToPeak',           [],...
    'CWT_ThetaAlpha',           [],...
    'Ref_Region',               [],...
    'Ref_NegativePeak',         [],...
    'Ref_PositivePeak',         [],...
    'Ref_NegativeSlope',        [],...
    'Ref_PositiveSlope',        [],...
    'Ref_NotchAmp',             [],...
    'Burst_BurstId',            [],...
    'Burst_NumberOfWaves',      [],...
    'Burst_Density',            [],...      % Number of Waves/Second in Burst
    'Channels_Active',          [],...
    'Channels_Peak2PeakAmp',    [],...
    'Channels_Globality',       [],...   
    'Channels_NegativeMax',     [],...      % Peak negative amplitude in the channels
    'Channels_PositiveMax',     [],...
    'Travelling_Delays',        [],...
    'Travelling_DelayMap',      [],...
    'Travelling_Density',       [],...
    'Travelling_Streams',       []);

OSTCount = 0; % counts empty as one... fix!
STCount  = 0;

%% Info defaults
if ~isfield(Info, 'Parameters')
    display('Warning: No detection parameters found in Info; using defaults');
    Info.Parameters.CWT_hPass       = 3;
    Info.Parameters.CWT_lPass       = 7;
    Info.Parameters.CWT_StdThresh   = 2;
    Info.Parameters.CWT_ThetaAlpha  = 0.8;   % Theta/Alpha power
end

%% Loop for each Reference Wave
for ref_wave = 1:size(Data.STRef,1)
    
    OSTCount = length(ST); % counts empty as one... fix!
    
    %% --Continuous Wavelet Transform -- %%
    FreqRange   = Info.Parameters.CWT_hPass:Info.Parameters.CWT_lPass;
    Scale_theta  = (centfrq('morl')./FreqRange) * Info.Recording.sRate;
    Scale_alpha = (centfrq('morl')./[8:12]) * Info.Recording.sRate;

    Data.CWT{1}(ref_wave,:) = mean(cwt(Data.STRef(ref_wave,:), Scale_theta, 'morl'));
    Data.CWT{2}(ref_wave,:) = mean(cwt(Data.STRef(ref_wave,:), Scale_alpha, 'morl'));
    
    %% -- Process Slopes -- %%
    slopeData = [0 diff(Data.STRef(ref_wave,:))];    % Differential of reference data (smoothed for better notch detection) 
    slopeCWT  = [0 diff(Data.CWT{1}(ref_wave,:))];   % Differential of theta bands
    
    refMNP  = find(diff(sign(slopeData))==2); %Maximum Negative Point (trough of the wave)
    refMPP  = find(diff(sign(slopeData))==-2); %Maximum Negative Point (trough of the wave)
    MNP     = find(diff(sign(slopeCWT))== 2);  % Maximum Negative Point (trough of the wave)
    MPP     = find(diff(sign(slopeCWT))==-2);  % Maximum Positive Point (peaks of the wave)
    
    % Check for earlier MPP than MNP
    if MNP(1) < MPP(1)
        MNP(1) = [];
    end
    % Check that last MNP has a later MPP
    if MNP(end) > MPP(end)
        MNP(end)=[];
    end
    
    %% -- Calculate Amplitude Threshold Criteria -- %%
    StdMor = mad(Data.CWT{1}(ref_wave,MNP),1); % Returns the absolute deviation from the median (to avoid outliers)
    Info.Parameters.CWT_AmpThresh(ref_wave) = (StdMor*Info.Parameters.CWT_StdThresh*2)+abs(mean(Data.CWT{1}(ref_wave,MNP))); % StdThresh standard deviations from each side      
    
    %% Failed Collection
    Info.Failed.FailedAtLength  = 0;   
    Info.Failed.FailedAtAmp     = 0;
    Info.Failed.FailedAtAlpha   = 0;
    
    % To check differences between next peaks found...
    AllPeaks = [ST.CWT_NegativePeak];
     
    % TODO: Test for amplitude/wavelength criteria outside loop
    
    % Loop through each MNP in the theta range data
    for i = 1:length(MNP) - 1
        
        % Use this when looking for a specific wave not found and set a breakpoint...
%         if refWave == 1 && MPP(i) > 71130
%             x = 1;
%         end
        
        %% -- Wavelength/Time Criteria -- %%
        
        % TODO: Wavelength criteria should be on reference, not CWT    
        
        % MPP -> MNP Hard Time Criteria
        if abs(MPP(i)-MNP(i)) > (1/(Info.Parameters.CWT_hPass-0.5)/2)*Info.Recording.sRate || abs(MPP(i)-MNP(i)) < (1/(Info.Parameters.CWT_lPass+0.5)/2)*Info.Recording.sRate
            Info.Failed.FailedAtLength = Info.Failed.FailedAtLength + 1;
            continue;
        end

        % MPP -> MNP Soft Time Criteria (Must pass additional MNP Amplitude Test)  
        if abs(MPP(i)-MNP(i)) > (1/(Info.Parameters.CWT_hPass-0.1)/2)*Info.Recording.sRate || abs(MPP(i)-MNP(i)) < (1/(Info.Parameters.CWT_lPass+0.1)/2)*Info.Recording.sRate
            if Data.CWT{1}(ref_wave, MNP(i)) > -Info.Parameters.CWT_AmpThresh(ref_wave)*2
                Info.Failed.FailedAtLength = Info.Failed.FailedAtLength + 1;
                continue;
                
            end
        end        
        
        % MNP -> MPP2 Hard Time Criteria
        if abs(MNP(i)-MPP(i+1)) > (1/(Info.Parameters.CWT_hPass-0.5)/2)*Info.Recording.sRate || abs(MNP(i)-MPP(i+1)) < (1/(Info.Parameters.CWT_lPass+0.5)/2)*Info.Recording.sRate
            Info.Failed.FailedAtLength = Info.Failed.FailedAtLength + 1;
            continue;
        end

        % MNP -> MPP2 Soft Time Criteria (Must pass additional MNP Amplitude Test)       
        if abs(MNP(i)-MPP(i+1)) > (1/(Info.Parameters.CWT_hPass-0.2)/2)*Info.Recording.sRate || abs(MNP(i)-MPP(i+1)) < (1/(Info.Parameters.CWT_lPass+0.2)/2)*Info.Recording.sRate
            if Data.CWT{1}(ref_wave, MNP(i)) > -Info.Parameters.CWT_AmpThresh(ref_wave)*2
                Info.Failed.FailedAtLength = Info.Failed.FailedAtLength + 1;
                continue;
            end
        end    
        
        %% -- Amplitude Criteria -- %%
        % Test MPP->MNP Amplitude
        MPP2MNP = Data.CWT{1}(ref_wave, MPP(i)) - Data.CWT{1}(ref_wave,MNP(i));
        
        % TODO: Burst adjustment ratio should be an external parameter
        
        % Check for burst here in order to temporarily lower the threshold...
        if STCount > 1
            if abs(ST(STCount).CWT_End-MPP(i)) < Info.Recording.sRate*Info.Parameters.Burst_Length
                % if there is a previous wave...
                if MPP2MNP < Info.Parameters.CWT_AmpThresh(ref_wave)*1.8
                    Info.Failed.FailedAtAmp  = Info.Failed.FailedAtAmp+1;
                    continue;
                end
            else
                % if the wave is isolated...
                if MPP2MNP < Info.Parameters.CWT_AmpThresh(ref_wave)*2
                    Info.Failed.FailedAtAmp  = Info.Failed.FailedAtAmp+1;
                    continue;
                end
            end
        end
        
        % Test MNP->MPP Amplitude
        MNP2MPP = Data.CWT{1}(ref_wave,MPP(i+1)) - Data.CWT{1}(ref_wave, MNP(i));
        
                % Check for burst here in order to temporarily lower the threshold...
        if STCount > 1
            if abs(ST(STCount).CWT_End-MPP(i)) < Info.Recording.sRate*Info.Parameters.Burst_Length
                % if there is a previous wave...
                if  MNP2MPP < Info.Parameters.CWT_AmpThresh(ref_wave)*1.8
                    Info.Failed.FailedAtAmp  = Info.Failed.FailedAtAmp+1;
                    continue;
                end
            else
                % if the wave is isolated...
                if  MNP2MPP < Info.Parameters.CWT_AmpThresh(ref_wave)*2
                    Info.Failed.FailedAtAmp  = Info.Failed.FailedAtAmp+1;
                    continue;
                end
            end
        end
        
        % Test Theta/Alpha Amplitude Ratio 
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        AlphaAmp = max(Data.CWT{2}(ref_wave, MPP(i):MPP(i+1)))-min(Data.CWT{2}(ref_wave,MPP(i):MPP(i+1)));
        ThetaAlpha = max(MPP2MNP,MNP2MPP)/AlphaAmp;
        if ThetaAlpha < Info.Parameters.CWT_ThetaAlpha
            Info.Failed.FailedAtAlpha  = Info.Failed.FailedAtAlpha+1;
            continue;
        end            
                      
        %% Look at Original Wave
        % Find notches over minimal amplitude criterion
        nPeaks = refMNP(refMNP > MPP(i) & refMNP < MPP(i+1));
        pPeaks = refMPP(refMNP > MPP(i) & refMNP < MPP(i+1));

        if nPeaks(1)<pPeaks(1)
            pPeaks = [MPP(i) pPeaks];
        end
        if nPeaks(end)>pPeaks(end)
            pPeaks = [pPeaks MPP(i+1)];
        end
        
        notches = [];
        for j = 1:length(nPeaks);
            
            if Data.STRef(ref_wave, pPeaks(j)) - Data.STRef(ref_wave, nPeaks(j)) < 10 || Data.STRef(ref_wave, pPeaks(j+1)) - Data.STRef(ref_wave, nPeaks(j)) < 10
                continue;
            end
            
            notches(end+1) = nPeaks(j);
        end

        [~, Ref_NegPeakId] = min(Data.STRef(ref_wave,MPP(i):MPP(i+1)));
        [~, Ref_PosPeakId] = max(Data.STRef(ref_wave,MNP(i):MNP(i+1)));
                
        %% Save Wave to Structure
        
        % Check if the SW has already been found in another reference channel
        if ref_wave > 1
            [c, STid] = max(double(AllPeaks > MPP(i)) + double(AllPeaks < MPP(i+1)));
            if c == 2              
                % Check which region has the bigger P2P wave...
                if abs(MNP2MPP) > ST(STid).CWT_PeakToPeak
                    % If the new region does then overwrite previous data with larger reference
                    ST(STid).Ref_Region          = [ref_wave, ST(STid).Ref_Region];
                    ST(STid).Ref_NegativePeak    = Ref_NegPeakId+MPP(i);
                    ST(STid).Ref_PositivePeak    = Ref_PosPeakId+MNP(i);
                    ST(STid).Ref_NegativeSlope   = mean(slopeData(MPP(i):(Ref_NegPeakId+MPP(i))));
                    ST(STid).Ref_PositiveSlope   = mean(slopeData((Ref_NegPeakId+MPP(i)):MPP(i+1)));
                    ST(STid).Ref_NotchAmp        = Data.STRef(ref_wave, notches);
                    
                    ST(STid).CWT_Start           = MPP(i);
                    ST(STid).CWT_NegativePeak    = MNP(i);
                    ST(STid).CWT_End             = MPP(i+1);
                    ST(STid).CWT_PeakToPeak      = MNP2MPP;
                    ST(STid).CWT_ThetaAlpha      = ThetaAlpha;   
                else
                    ST(STid).Ref_Region(end+1) = ref_wave;
                end
                
                continue;
            end
        end
        
        STCount = STCount+1;

        ST(STCount).Ref_Region          = ref_wave;
        ST(STCount).Ref_NegativePeak    = Ref_NegPeakId+MPP(i);
        ST(STCount).Ref_PositivePeak    = Ref_PosPeakId+MNP(i);
        ST(STCount).Ref_NegativeSlope   = mean(slopeData(MPP(i):(Ref_NegPeakId+MPP(i))));
        ST(STCount).Ref_PositiveSlope   = mean(slopeData((Ref_NegPeakId+MPP(i)):MPP(i+1)));
        ST(STCount).Ref_NotchAmp        = Data.STRef(ref_wave, notches);
        
        ST(STCount).CWT_Start           = MPP(i);
        ST(STCount).CWT_NegativePeak    = MNP(i);
        ST(STCount).CWT_End             = MPP(i+1);
        ST(STCount).CWT_PeakToPeak      = MNP2MPP;
        ST(STCount).CWT_ThetaAlpha      = ThetaAlpha;
        
        %% Plot Some Waves
%         if STCount > 10 && STCount < 15
%             Range = (1:size(Data.Raw,2))/Info.Recording.sRate;
%               window = 1*Info.Recording.sRate;
%             if MNP(i)>window
%                 figure('color', 'w'); plot(Range(MNP(i)-window:MNP(i)+window), Data.STRef(refWave,MNP(i)-window:MNP(i)+window), 'k'); hold on; plot(Range(MNP(i)-window:MNP(i)+window), Data.CWT{1}(refWave,MNP(i)-window:MNP(i)+window), 'b'); plot(Range(MNP(i)-window:MNP(i)+window), Data.CWT{2}(refWave,MNP(i)-window:MNP(i)+window), 'g');
%                 figure('color', 'w'); plot(Data.STRef(refWave,MNP(i)-window:MNP(i)+window), 'k'); hold on; plot(Data.CWT{1}(refWave,MNP(i)-window:MNP(i)+window)); plot(Data.CWT{2}(refWave,MNP(i)-window:MNP(i)+window), 'g');
%                 set(gca, 'XLim', [Range(MNP(i)-window),Range(MPP(i+1)+window)]);
%             else
%                 figure('color', 'w'); plot(Range(1:MPP(i+1)+window), Data.STRef(refWave,1:MPP(i+1)+window), 'k'); hold on; plot(Range(1:MPP(i+1)+window), Data.CWT{1}(refWave,1:MPP(i+1)+window));
%                 figure('color', 'w'); plot(Data.STRef(refWave,1:MPP(i+1)+window), 'k'); hold on; plot(Data.CWT{1}(refWave,1:MPP(i+1)+window)); plot(Data.CWT{2}(refWave,1:MPP(i+1)+window), 'g');
%                 set(gca, 'XLim', [Range(1),Range(MPP(i+1)+window)]);

%             end
%         end
        
    end
    
    if ref_wave == 1
        fprintf(1, 'Information: %d saw-tooth waves waves found in reference wave \n', length(ST));
    else
        fprintf(1, 'Information: %d saw-tooth waves added from region %d \n', length(ST)-OSTCount, ref_wave);
    end
    
end

%% Sort ST by main peak (useful for multiple reference regions/types
AllPeaks = [ST.CWT_NegativePeak];
[~,sortId] = sort(AllPeaks);
ST = ST(sortId);

%% Burst Calculation
% If there are no waves found than just return
if length(ST)<2; 
    return; 
end;

% Allocate nans to all data
[ST(:).Burst_BurstId]         = deal(nan);
[ST(:).Burst_NumberOfWaves]   = deal(nan);
[ST(:).Burst_Density]         = deal(nan);
    
% pre-allocate counting variables
flag_ST = true(length(ST), 1);
BurstId = 0;

% loop through each wave
for i = 1:length(ST)-1 
      
    % see if the next wave is close to the current one
    if flag_ST(i) && ST(i+1).Ref_NegativePeak-ST(i).Ref_NegativePeak < ...
            Info.Recording.sRate*Info.Parameters.Burst_Length
    
        % start the count
        BurstCount = 1;
        Growing = i;
        
        % check the next waves until it isn't close anymore
        for j = i:length(ST)-1
                                  
            if ST(j+1).Ref_NegativePeak-ST(j).Ref_NegativePeak < Info.Recording.sRate*Info.Parameters.Burst_Length
                
                % add the wave indices to the burst indices
                Growing(end + 1) = j + 1;
                BurstCount = BurstCount + 1;
                flag_ST(j+1) = false;
                
            else
                
                % break the loop if the next wave is not in the burst
                BurstId = BurstId+1;
                break;
                
            end
            
        end
        
    % add the burst information to all the ST waves involved
    [ST(Growing).Burst_BurstId]         = deal(BurstId);
    [ST(Growing).Burst_NumberOfWaves]   = deal(BurstCount);
    [ST(Growing).Burst_Density]         = deal((BurstCount/(ST(j+1).Ref_NegativePeak-ST(i).Ref_NegativePeak))*Info.Recording.sRate);
    
    end
end