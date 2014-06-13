function [Data, Info, SS] = swa_FindSSRef(Data, Info)
% Automatic spindle detection on a reference channel using continuous 
% wavelet transform

%% Initialise the SS Structure
SS = struct(...
    'Ref_Region',               [],...
    'Ref_Type',                 [],...
    'Ref_Start',                [],...
    'Ref_End',                  [],...    
    'Ref_NegativePeak',         [],...
    'Ref_PositivePeak',         [],...
    'Ref_Peak2Peak',            [],...
    'Ref_Length',               [],...
    'Ref_NumberOfWaves',        [],...
    'Ref_Symmetry',             [],...
    'Channels_Active',          [],...
    'Channels_Peak2PeakAmp',    [],...
    'Channels_Globality',       [],...   
    'Travelling_Delays',        [],...
    'Travelling_DelayMap',      [],...
    'Travelling_Density',       [],...
    'Travelling_Streams',       []);

OSTCount = 0;
SSCount  = 0;

%% Info defaults
if ~isfield(Info, 'Parameters')
    display('Warning: No detection parameters found in Info; using defaults');
    Info.Parameters.CWT_hPass(1)    = 11;
    Info.Parameters.CWT_lPass(1)    = 13;
    Info.Parameters.CWT_hPass(1)    = 14;
    Info.Parameters.CWT_lPass(1)    = 16;
    Info.Parameters.CWT_StdThresh   = 2;
end

% Wavelet Parameters
FreqRange{1}   = Info.Parameters.CWT_hPass(1):0.5:Info.Parameters.CWT_lPass(2);
FreqRange{2}   = Info.Parameters.CWT_hPass(1):0.5:Info.Parameters.CWT_lPass(1);
FreqRange{3}   = Info.Parameters.CWT_hPass(2):0.5:Info.Parameters.CWT_lPass(2);

% Get scale values using inverse of pseudo-frequencies
scaleFull = (centfrq('morl')./FreqRange{1})*Info.sRate;
scaleSlow = (centfrq('morl')./FreqRange{2})*Info.sRate;
scaleFast = (centfrq('morl')./FreqRange{3})*Info.sRate;

%% Loop for each Reference Wave
for refWave = 1:size(Data.SSRef,1)
    
    OSTCount = length(SS); % counts empty as one... fix!
    
    %% --Continuous Wavelet Transform -- %%
    Data.CWT{1}(refWave,:) = mean(cwt(Data.SSRef(refWave,:), scaleFull, 'morl'), 1);
    
    % Calculate the power of each wavelet
    window = ones((Info.sRate/10),1)/(Info.sRate/10); % create 140ms window to convolve with

    powerData = Data.CWT{1}(refWave,:).^2;
    powerData = filter(window,1,powerData); % take the moving average using the above window
    
    %% -- Threshold crossings -- %%
    % Calculate power threshold criteria
    stdMor = mad(powerData,1); % Returns the absolute deviation from the median (to avoid outliers)
    Info.Parameters.CWT_AmpThresh(refWave) = (stdMor*Info.Parameters.CWT_StdThresh*2)+median(powerData); % StdThresh standard deviations from each side      
    
    signData    = sign(powerData - Info.Parameters.CWT_AmpThresh(refWave));       % gives the sign of data
    DZC = find(diff(signData) == -2); % -2 indicates when the sign goes from 1 to -1
    UZC = find(diff(signData) == 2);
    
    % Check for earlier initial UZC than DZC
    if DZC(1)<UZC(1)
        DZC(1)=[];
    end
    
    % Check for last DZC with no UZC
    if length(DZC)>length(UZC)
        DZC(end) = [];
    end
    
    %% Check Soft Minimum Length (30% less than actual minimum)
    SSLengths = DZC-UZC;
    minLength = (Info.Parameters.Ref_MinLength/1.3)*Info.sRate;
    
    UZC(SSLengths < minLength) = [];
    DZC(SSLengths < minLength) = [];
    
    %% Find negative troughs in the power signal near the crossings
    slopePower = [0 diff(powerData)];  % Differential of reference data (smoothed for better notch detection)     
    powerMNP   = find(diff(sign(slopePower))==2); %Maximum Negative Point (trough of the wave)
    
    startSS = [];
    endSS = [];
    % Calculate the actual start of the spindle from powerData
    for i = 1:length(UZC)
        startSS(i) = powerMNP(sum(UZC(i)-powerMNP > 0));
        endSS(i) = powerMNP(sum(DZC(i)-powerMNP > 0)+1);
    end
    
    %% Check Hard Minimum Length
    SSLengths = endSS-startSS;
    minLength = (Info.Parameters.Ref_MinLength)*Info.sRate;
    
    startSS(SSLengths < minLength) = [];
    endSS(SSLengths < minLength) = [];
    SSLengths(SSLengths < minLength) = [];
    
    %% Check neighbouring frequencies to ensure its spindle specific
    % To do

    % Find mid point of waves calculated so far
    allSS = [SS.Ref_Start]+[SS.Ref_Length]/2;

    
    %% Loop through each spindle found
    for i = 1:length(startSS)
        
        % Find the local peaks and troughs
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        % Calculate the slope of the original wave
        slopeRef  = [0 diff(Data.SSRef(refWave,startSS(i):endSS(i)))];
        % Find all the peaks, both positive and negative
        peakAmp     = Data.SSRef(refWave, startSS(i)-1+find(abs(diff(sign(slopeRef)))== 2));
        [peak2Peak, id]   = max(abs(diff(peakAmp)));
        
        % Check spindle type (fast or slow
        slow = mean(cwt(Data.SSRef(refWave,startSS(i):endSS(i)), scaleSlow, 'morl'), 1);
        fast = mean(cwt(Data.SSRef(refWave,startSS(i):endSS(i)), scaleFast, 'morl'), 1);
        [~,type] = max([max(abs(slow)), max(abs(fast))]);
        
        %% Save Wave to Structure
        % Check if the SS has already been found in another reference channel
        if refWave > 1
            [c, STid] = max(double(allSS > startSS(i)) + double(allSS < endSS(i)));
            if c == 2              
                % Check which region has the bigger P2P wave...
                if peak2Peak > SS(STid).Ref_Peak2Peak
                    % If the new region does then overwrite previous data with larger reference
                    SS(STid).Ref_Region          =      [refWave, SS(STid).Ref_Region];
                    SS(STid).Ref_NegativePeak    =      min(peakAmp);
                    SS(STid).Ref_PositivePeak    =      max(peakAmp);
                    SS(STid).Ref_Peak2Peak       =      peak2Peak;
                    SS(STid).Ref_Type            =      type;
                    SS(STid).Ref_Start           =      startSS(i);
                    SS(STid).Ref_End             =      endSS(i);                    
                    SS(STid).Ref_Length          =      SSLengths(i);
                    SS(STid).Ref_NumberOfWaves   =      length(peakAmp)/2;
                    SS(STid).Ref_Symmetry        =      id/(length(peakAmp)-1);
                else
                    SS(STid).Ref_Region(end+1)   = refWave;
                end
                
                continue;
            end
        end
        
        SSCount = SSCount+1;

        SS(SSCount).Ref_Region          =      refWave;
        SS(SSCount).Ref_NegativePeak    =      min(peakAmp);
        SS(SSCount).Ref_PositivePeak    =      max(peakAmp);
        SS(SSCount).Ref_Peak2Peak       =      peak2Peak;
        SS(SSCount).Ref_Type            =      type;
        SS(SSCount).Ref_Start           =      startSS(i);
        SS(SSCount).Ref_End             =      endSS(i);
        SS(SSCount).Ref_Length          =      SSLengths(i);
        SS(SSCount).Ref_NumberOfWaves   =      length(peakAmp)/2;
        SS(SSCount).Ref_Symmetry        =      id/(length(peakAmp)-1);

        
        %% Plot Some Waves
%         if STCount > 10 && STCount < 15
%             Range = (1:size(Data.REM,2))/Info.sRate;
%               window = 1*Info.sRate;
%             if MNP(i)>window
%                 figure('color', 'w'); plot(Range(MNP(i)-window:MNP(i)+window), Data.SSRef(refWave,MNP(i)-window:MNP(i)+window), 'k'); hold on; plot(Range(MNP(i)-window:MNP(i)+window), Data.CWT{1}(refWave,MNP(i)-window:MNP(i)+window), 'b'); plot(Range(MNP(i)-window:MNP(i)+window), Data.CWT{2}(refWave,MNP(i)-window:MNP(i)+window), 'g');
%                 figure('color', 'w'); plot(Data.SSRef(refWave,MNP(i)-window:MNP(i)+window), 'k'); hold on; plot(Data.CWT{1}(refWave,MNP(i)-window:MNP(i)+window)); plot(Data.CWT{2}(refWave,MNP(i)-window:MNP(i)+window), 'g');
%                 set(gca, 'XLim', [Range(MNP(i)-window),Range(MPP(i+1)+window)]);
%             else
%                 figure('color', 'w'); plot(Range(1:MPP(i+1)+window), Data.SSRef(refWave,1:MPP(i+1)+window), 'k'); hold on; plot(Range(1:MPP(i+1)+window), Data.CWT{1}(refWave,1:MPP(i+1)+window));
%                 figure('color', 'w'); plot(Data.SSRef(refWave,1:MPP(i+1)+window), 'k'); hold on; plot(Data.CWT{1}(refWave,1:MPP(i+1)+window)); plot(Data.CWT{2}(refWave,1:MPP(i+1)+window), 'g');
%                 set(gca, 'XLim', [Range(1),Range(MPP(i+1)+window)]);

%             end
%         end
        
    end
    
    if refWave == 1
        fprintf(1, 'Information: %d spindle bursts found in reference wave \n', length(SS));
    else
        fprintf(1, 'Information: %d spindle bursts added from region %d \n', length(SS)-OSTCount, refWave);
    end
    
end

%% Sort ST by main peak
allSS = [SS.Ref_Start];
[~,sortId] = sort(allSS);
SS = SS(sortId);