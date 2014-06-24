function [SW, Data, Info] = swa_FindSWChannels(SW, Data, Info)

if ~isfield(Info, 'ChN');
    fprintf(1,'Calculating: Channel Neighbours...');
    Info.ChN = swa_ChN(Info.Electrodes);
    fprintf(1,'Done. \n');
else
    fprintf(1,'Information: Using channels neigbourhood in ''Info''. \n');
end

if strcmp(Info.Parameters.Ref_Method, 'Envelope')
    if ~isfield(Info.Parameters, 'Channels_CorrThresh')
        fprintf(1, 'Warning: No further SW parameters found in Info; using defaults \n');
        Info.Parameters.Channels_CorrThresh = 0.9;
        Info.Parameters.Channels_WinSize    = 0.2;
    end
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
switch Info.Parameters.Ref_Method
    case 'Envelope'
        
        for nSW = 1:length(SW)
            
            waitbar(nSW/length(SW),WaitHandle,sprintf('Slow Wave %d of %d',nSW, length(SW)))
            
            shortData = Data.Filtered(:,SW(nSW).Ref_PeakId-win:SW(nSW).Ref_PeakId+win);
            refData = Data.Ref(:,SW(nSW).Ref_PeakId-win:SW(nSW).Ref_PeakId+win);
            
            %% Cross correlate with the reference channel at multiple lags
            for ch = 1:size(shortData,1)
                cc(ch,:) = xcorr(shortData(ch,:), refData, win, 'coeff');
            end
            
            [maxCC, maxID]      = max(cc,[],2); % find the maximum correlation and location
            Channels    = maxCC > Info.Parameters.Channels_CorrThresh; % channels with correlation above threshold
            
            % if no channels correlate well with the reference then delete the SW
            % and continue... [should try to correlate with maximum channel]
            if sum(Channels)==0
                ToDelete(end+1)=nSW;
                continue
            end
            
            %% Minimum amplitude threshold (10% of maximum)
            x = nan(length(Info.Electrodes),1);
            x(Channels,:) = min(shortData(Channels,:),[],2);
            Channels(x > Info.Parameters.Ref_NegAmpMin/10) = false;
            
            %% Cluster Test
            % Only take largest single cluster to avoid outliers
            Clusters = swa_ClusterTest(double(Channels), Info.ChN, 0.01);
            
            nClusters = unique(Clusters);
            if length(nClusters) > 2
                maxCluster = 0;
                for i = 2:length(nClusters)
                    sCluster = sum(Clusters == nClusters(i));
                    if sCluster > maxCluster
                        maxCluster = sCluster;
                        keepCluster = i;
                    end
                end
                Channels = Clusters == nClusters(keepCluster);
            end
            
            %% Calculate peak negative amplitude and channel
            
            [SW(nSW).Channels_NegAmp, id] = min(x);
            SW(nSW).Channels_NegAmpId = SW(Channels(id));
            %% Test for type 1 or 2 wave
            
            
            %% Processing for multi-peak waves
            
            
            %% Delay Calculation
            SW(nSW).Travelling_Delays = nan(length(Info.Electrodes),1);
            SW(nSW).Travelling_Delays(Channels)...
                = maxID(Channels) - min(maxID(Channels));
            
            SW(nSW).Channels_Globality  = sum(Channels)/length(Channels)*100;
            SW(nSW).Channels_Active 	= Channels;
        end
                
    case 'MDC'
        
        for nSW = 1:length(SW)
            
            waitbar(nSW/length(SW),WaitHandle,sprintf('Slow Wave %d of %d',nSW, length(SW)))
            
            shortData = Data.Filtered(:,SW(nSW).Ref_PeakId-win:SW(nSW).Ref_PeakId+win);
            
            %% Minimum amplitude threshold for channels
            [minChAmp, minChId] = min(shortData,[],2);
            SW(nSW).Channels_Active = minChAmp < -Info.Parameters.Ref_NegAmpMin;
            % Save peak negative amplitude and channel
            [SW(nSW).Channels_NegAmp, SW(nSW).Channels_NegAmpId] = min(minChAmp);

            %% Peak to Peak Check
            % MDC Test for peak to peak amplitude
            posPeakAmp = nan(size(minChAmp));
            for nCh = find(SW(nSW).Channels_Active == 1)'
                posPeakAmp(nCh) = max(shortData(nCh,minChId(nCh):end));
            end
            SW(nSW).Channels_Active(posPeakAmp-minChAmp < Info.Parameters.Ref_Peak2Peak) = false;
            
            %% Wavelength Check
            % Not performed as some channels do not actually cross zero but
            % show all other characteristics of the slow wave
            
            %% Sufficient Channels Check (more than 0)
            if sum(SW(nSW).Channels_Active)==0
                ToDelete(end+1)=nSW;
                continue
            end
            
            %% Delay Calculation
            % Using negative peak id
            SW(nSW).Travelling_Delays = nan(length(Info.Electrodes),1);
            SW(nSW).Travelling_Delays(SW(nSW).Channels_Active)...
                = minChId(SW(nSW).Channels_Active) - min(minChId(SW(nSW).Channels_Active));
            
            SW(nSW).Channels_Globality   = sum(SW(nSW).Channels_Active)/length(SW(nSW).Channels_Active)*100;            
            
            
        end
            
end

fprintf(1, 'Information: %d slow waves were removed due insufficient criteria \n', length(ToDelete));
delete(WaitHandle)       % DELETE the waitbar; don't try to CLOSE it.
SW(ToDelete)=[];
