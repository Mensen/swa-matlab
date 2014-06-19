function [Data, Info, SS] = swa_FindSSChannels(Data, Info, SS)
% Automatic spindle detection on all channels after initial spindles have 
% been detected in a reference channel 

% Check for necessary parameters in the Info
if ~isfield(Info.Parameters, 'Channels_WinSize')
    fprintf(1, 'Warning: No further SS parameters found in Info; using defaults \n');
    Info.Parameters.Channels_WinSize    = 0.1;
    Info.Parameters.Channels_ThreshFactor = 0.8;
end

%% Filter the original signal
if Info.Parameters.Filter_Apply
    if ~isfield(Data, 'Filtered')
        fprintf(1, 'Calculating: Filtering Dataset...');
        switch Info.Parameters.Filter_Method
            case 'Chebyshev'
                Wp=[Info.Parameters.Filter_hPass Info.Parameters.Filter_lPass]/(Info.sRate/2); % Filtering parameters
                Ws=[Info.Parameters.Filter_hPass/5 Info.Parameters.Filter_lPass*2]/(Info.sRate/2); % Filtering parameters
                Rp=3;
                Rs=10;
                [n, Wn]=cheb2ord(Wp,Ws,Rp,Rs);
                [bbp,abp]=cheby2(n,Rs,Wn); % Loses no more than 3 dB in pass band and has at least 10 dB attenuation in stop band
                clear pass* stop* Rp Rs W* n;
                Data.Filtered = filtfilt(bbp, abp, Data.SWS')';
                
            case 'Buttersworth'
                fhc = Info.Parameters.Filter_hPass/(Info.sRate/2);
                flc = Info.Parameters.Filter_lPass/(Info.sRate/2);
                [b1,a1] = butter(Info.Parameters.Filter_order,fhc,'high');
                [b2,a2] = butter(Info.Parameters.Filter_order,flc,'low');
                
                Data.Filtered = filtfilt(b1, a1, Data.SWS');
                Data.Filtered = filtfilt(b2, a2, Data.Filtered)';
        end
        fprintf(1, 'Done. \n');
    else
        display('Information: Data not re-filtered; using data supplied');
    end
end

% parameters for cwt
FreqRange   = Info.Parameters.CWT_hPass(1):0.5:Info.Parameters.CWT_lPass(2);
fullScale   = (centfrq('morl')./FreqRange)*Info.sRate;
powerWindow = ones((Info.sRate/10),1)/(Info.sRate/10); % create 100ms window to convolve with

% calculate cwt for each channel
cwtData = zeros(size(Data.Raw));
WaitHandle = waitbar(0,'Please wait...', 'Name', 'Calculating Wavelets');
for i = 1:size(Data.Raw,1)
    waitbar(i/size(Data.Raw,1),WaitHandle,sprintf('Channel %d of %d',i, size(Data.Raw,1)))
    cwtData(i,:) = mean(cwt(Data.Raw(i,:),fullScale,'morl'));
end
delete(WaitHandle);

% calculate the power of each cwt
powerData = cwtData.^2;
powerData = filter(powerWindow,1,powerData')';

% calculate individual channel thresholds
stdMor = mad(powerData',1)'; % Returns the absolute deviation from the median (to avoid outliers)
thresholds = (stdMor.*Info.Parameters.CWT_StdThresh*Info.Parameters.Channels_ThreshFactor)+median(powerData')';

% when and for how long does the power cross the threshold
signData    = sign(powerData - repmat(thresholds, [1, size(powerData,2)]));       % gives the sign of data
minLength = (Info.Parameters.Ref_MinLength/1.3)*Info.sRate;
    
% time around the reference wave for other channels
win = round(Info.Parameters.Channels_WinSize*Info.sRate);

%% Find corresponding channels from the reference wave
WaitHandle = waitbar(0,'Please wait...', 'Name', 'Finding Spindles in Channels...');
ToDelete=[];

for nSS = 1:length(SS)
    
    waitbar(nSS/length(SS),WaitHandle,sprintf('Spindle %d of %d',nSS, length(SS)))
    
    % calculate the sample range
    range = SS(nSS).Ref_Start-win:SS(nSS).Ref_End+win;
    
%     % Get the shorter time series data with a window on each side
%     if Info.Parameters.Filter_Apply
%         shortData = Data.Filtered(:,SS(nSS).Ref_Start-win:SS(nSS).Ref_End+win);
%     else
%         shortData = Data.Raw(:,SS(nSS).Ref_Start-win:SS(nSS).Ref_End+win);
%     end
%     % Reference data is taken from start to end of the spindle
%     refData = Data.SSRef(SS(nSS).Ref_Region(1),SS(nSS).Ref_Start:SS(nSS).Ref_End);
    
    %% Calculate the continuous wavelet transform and power
%     cwtData = zeros(size(shortData));
%     % looping fairly slow
%     for i = 1:size(shortData,1)
%         cwtData(i,:) = mean(cwt(shortData(i,:),fullScale,'morl'));
%     end
%     
%     powerData = cwtData.^2;
%     powerData = filter(powerWindow,1,powerData')'; % take the moving average using the above window

    shortPower = powerData(:,range);

    %% Maximum power and duration criteria
    shortSign = signData(:,range);
    Channels = sum(shortSign > 0, 2) > minLength*Info.Parameters.Channels_ThreshFactor;
    
    % find the time of the peak of the powerData (shortPower)
    shortPower = shortPower(Channels, :);
    [~, maxID]      = max(shortPower,[],2); 
    
    
%     %% Cross correlate with the reference channel at multiple lags
%     % cross correlation will simply pick up near-reference channels!
%     % should work on alternative method
%     cc = swa_xcorr(refData, shortData, win);
%     
%     % find the maximum correlation and location
%     [maxCC, maxID]      = max(cc,[],2); 
%     % channels with correlation above threshold
%     Channels    = maxCC > Info.Parameters.Channels_CorrThresh; 
    
    %% Calculate peak to peak  
    % find the slopes of the raw data
    if Info.Parameters.Filter_Apply
        slopeData  = diff(Data.Filtered(Channels, range), 1, 2);
    else
        slopeData  = diff(Data.Raw(Channels, range), 1, 2);
    end
    
    peak2Peak = nan(sum(Channels),1);  
    % Find all the peaks, both positive and negative
    for ch = 1:size(slopeData, 1)
        % Find all the peaks, both positive and negative
        peakAmp = Data.Raw(ch, SS(nSS).Ref_Start+find(abs(diff(sign(slopeData(ch,:)), 1, 2)== 2)));
        % if a channel has less than 3 peaks, delete it
        if length(peakAmp) < 3
            peak2Peak(ch,:) = nan;
            continue;
        end
        peak2Peak(ch,:)   = max(abs(diff(peakAmp)));
    end
    
    % continue if no channels are left after duration and peak2peak checks
    if sum(Channels) == 0
        ToDelete(end+1) = nSS;
        continue
    end
    
    %% Save to SS structure
    % pre-allocate using nans
    SS(nSS).Channels_Peak2PeakAmp = nan(length(Info.Electrodes),1);
    SS(nSS).Channels_Peak2PeakAmp(Channels) = peak2Peak;
    
    % save remaining channels to structure
    SS(nSS).Channels_Active = abs(SS(nSS).Channels_Peak2PeakAmp) > 0;
    SS(nSS).Channels_Globality  = sum(SS(nSS).Channels_Active)/length(SS(nSS).Channels_Active)*100;
         
    % Find delays based on time of maximum power
    SS(nSS).Travelling_Delays = nan(length(Info.Electrodes),1);
    SS(nSS).Travelling_Delays(Channels) = maxID - min(maxID);
    
end

if ~isempty(ToDelete)
    fprintf(1, 'Information: %d spindle(s) were removed due insufficient criteria \n', length(ToDelete));
    SS(ToDelete)=[];
end

delete(WaitHandle)       % DELETE the waitbar; don't try to CLOSE it.

