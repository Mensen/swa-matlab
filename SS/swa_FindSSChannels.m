function [Data, Info, SS] = swa_FindSSChannels(Data, Info, SS)
% Automatic spindle detection on all channels after initial spindles have 
% been detected in a reference channel 

% Check for necessary parameters in the Info
if ~isfield(Info.Parameters, 'Channels_CorrThresh')
    fprintf(1, 'Warning: No further SS parameters found in Info; using defaults \n');
    Info.Parameters.Channels_CorrThresh = 0.9;
    Info.Parameters.Channels_WinSize    = 0.1;
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

win = round(Info.Parameters.Channels_WinSize*Info.sRate);

%% Find corresponding channels from the reference wave
WaitHandle = waitbar(0,'Please wait...', 'Name', 'Finding Slow Waves...');
ToDelete=[];

for nSS = 1:length(SS)
    
    waitbar(nSS/length(SS),WaitHandle,sprintf('Slow Wave %d of %d',nSS, length(SS)))
    
    % Get the shorter time series data with a window on each side
    if Info.Parameters.Filter_Apply
        shortData = Data.Filtered(:,SS(nSS).Ref_Start-win:SS(nSS).Ref_End+win);
    else
        shortData = Data.Raw(:,SS(nSS).Ref_Start-win:SS(nSS).Ref_End+win);
    end
    % Reference data is taken from start to end of the spindle
    refData = Data.SSRef(SS(nSS).Ref_Region(1),SS(nSS).Ref_Start:SS(nSS).Ref_End);
    
    %% Cross correlate with the reference channel at multiple lags
    % cross correlation will simply pick up near-reference channels!
    % should work on alternative method
    cc = swa_xcorr(refData, shortData, win);
    
    % find the maximum correlation and location
    [maxCC, maxID]      = max(cc,[],2); 
    % channels with correlation above threshold
    Channels    = maxCC > Info.Parameters.Channels_CorrThresh; 
    
    % if no channels correlate well with the reference then delete the SS
    % and continue... [should try to correlate with maximum channel]
    if sum(Channels)==0
        ToDelete(end+1)=nSS;
        continue
    end
    
    %% Calculate peak to peak
    % save items to the SS
    SS(nSS).Channels_Active 	= Channels;
    
    % pre-allocate using nans
    SS(nSS).Channels_Peak2PeakAmp = nan(length(Info.Electrodes),1);
    
    % find the slopes of the raw data
    if Info.Parameters.Filter_Apply
        slopeRef  = diff(Data.Filtered(Channels, SS(nSS).Ref_Start:SS(nSS).Ref_End), 1, 2);
    else
        slopeRef  = diff(Data.Raw(Channels, SS(nSS).Ref_Start:SS(nSS).Ref_End), 1, 2);
    end
    
    peak2Peak = zeros(sum(Channels),1);
    % Find all the peaks, both positive and negative
    for ch = 1:size(slopeRef, 1)
        peakAmp = Data.Raw(ch, SS(nSS).Ref_Start+find(abs(diff(sign(slopeRef(ch,:)), 1, 2)== 2)));
        peak2Peak(ch,:)   = max(abs(diff(peakAmp)));
    end
    
    SS(nSS).Channels_Peak2PeakAmp(Channels) = peak2Peak;
    SS(nSS).Channels_Globality  = sum(Channels)/length(Channels)*100;
       
    %% Delay Calculation
    SS(nSS).Travelling_Delays = nan(length(Info.Electrodes),1);
    SS(nSS).Travelling_Delays(Channels)...
        = maxID(Channels) - min(maxID(Channels));
    
end

if ~isempty(ToDelete)
    fprintf(1, 'Information: %d slow waves were removed due insufficient criteria \n', length(ToDelete));
    SS(ToDelete)=[];
end

delete(WaitHandle)       % DELETE the waitbar; don't try to CLOSE it.

