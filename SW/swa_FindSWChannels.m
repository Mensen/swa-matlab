function [Data, Info, SW] = swa_FindSWChannels(Data, Info, SW, flag_progress)
% function to find the slow waves present at each channel given the parameters
% already calculated for the reference wave

% check inputs
if nargin < 3
    error('current function requires at least 3 inputs: Data, Info, and SW')
end

if nargin < 4
    flag_progress = 1;
end

% check that some waves were found
% check for empty structure
if length(SW) < 1
    fprintf(1, 'Warning: Wave structure is empty \n');
    return
elseif length(SW) < 2
    if isempty(SW.Ref_Region)
        fprintf(1, 'Warning: Wave structure is empty \n');
        return
    end
end

% TODO: make cluster test parameter and available for threshold detection
if Info.Parameters.Channels_ClusterTest
    % check for previous channel neighbours calculation
    if ~isfield(Info.Recording, 'ChannelNeighbours');
        fprintf(1,'Calculating: Channel Neighbours...');
        Info.Recording.ChannelNeighbours = swa_channelNeighbours(Info.Electrodes);
        fprintf(1,' done. \n');
    else
        fprintf(1,'Information: Using channels neighbourhood in ''Info''. \n');
    end
end

% check for sufficient parameter inputs
if strcmp(Info.Parameters.Ref_Method, 'Envelope')
    if ~isfield(Info.Parameters, 'Channels_Threshold')
        fprintf(1, 'Warning: No further SW parameters found in Info; using defaults \n');
        Info.Parameters.Channels_Threshold = 0.9;
        Info.Parameters.Channels_WinSize    = 0.2;
    end
end

% Filter the original signal
% ~~~~~~~~~~~~~~~~~~~~~~~~~~

% TODO: Solve persistent 'out of memory' issues while raw and filtered
% files are kept in memory (potentially just filter relevant parts of data only)

% Check for previously filtered data
if isfield(Data, 'Filtered')
    % if the field exists but is empty then filter it
    if isempty(Data.Filtered)
        Data.Filtered = swa_filter_data(Data.Raw, Info);
    end
% if the field does not exist, filter the raw data
else
    fprintf(1,'Calculation: Filtering Data. \n');
    Data.Filtered = swa_filter_data(Data.Raw, Info);
end

% calculate the window size in samples around center point
win = round(Info.Parameters.Channels_WinSize * Info.Recording.sRate);

% Find corresponding channels from the reference wave
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if flag_progress
    WaitHandle = waitbar(0,'Please wait...', 'Name', 'Finding Slow Waves...');
end

% pre-allocate delete flag
ToDelete=[];

% Switch between the channel detection methods
switch Info.Parameters.Channels_Detection
    
    % Correlation Method
    % ^^^^^^^^^^^^^^^^^^
    case 'correlation'

        for nSW = 1:length(SW)

            if flag_progress
                waitbar(nSW/length(SW),WaitHandle,sprintf('Slow Wave %d of %d',nSW, length(SW)))
            end

            % check that the search window doesn't cross data start or end
            % TODO: improve check as these may be legitimate slow waves
            if SW(nSW).Ref_PeakInd - win * 2 < 1 || SW(nSW).Ref_PeakInd + win * 2 > Info.Recording.dataDim(2)
                ToDelete(end+1)=nSW;
                continue
            end
            % extract a small portion of the channel data around the

            % reference peak
            shortData   = Data.Filtered(:,SW(nSW).Ref_PeakInd - win * 2 ...
                        : SW(nSW).Ref_PeakInd + win * 2);
            % get only the negative portion of the reference peak
            refData     = mean(Data.SWRef(SW(nSW).Ref_Region, SW(nSW).Ref_PeakInd - win ...
                        : SW(nSW).Ref_PeakInd + win), 1);

            % cross correlate with the reference channel
            cc = swa_xcorr(refData, shortData, win);

            % find the maximum correlation and location
            [maxCC, maxID]      = max(cc,[],2);

            % cross correlation plot
%             [~, sort_ind] = sort(maxID, 1, 'ascend');
%             image_data = cc(sort_ind, :);
%             time_delay = ([-20:20] / Info.Recording.sRate) * 1000;
%             figure('color', 'w'); axes('nextPlot', 'add', 'yDir', 'reverse');
%             contourf(time_delay, 1:size(image_data, 1),...
%                 image_data, 15, ...
%                 'linestyle', 'none');
            
            % channels with correlation above threshold
            Channels = false(Info.Recording.dataDim(1),1);
            Channels(maxCC > Info.Parameters.Channels_Threshold) = true; 
            
            % if no channels correlate well with the reference then delete the SW
            % and continue... [should try to correlate with maximum channel]
            if sum(Channels)==0
                ToDelete(end+1)=nSW;
                continue
            end
            
            % Minimum amplitude threshold (10% of maximum)
            % ````````````````````````````````````````````
            SW(nSW).Channels_NegAmp = nan(length(Info.Electrodes),1);
            % TODO: make shortData only reflect the best correlating
            % portion as currently it could find another negative peak to
            % test minimum amp that doesn't correspond to peak of interest
            SW(nSW).Channels_NegAmp(Channels,:) = min(shortData(Channels,:),[],2);
            Channels(SW(nSW).Channels_NegAmp > mean(Info.Parameters.Ref_AmplitudeAbsolute)/10) = false;
            
            % Cluster Test
            % ````````````
            if Info.Parameters.Channels_ClusterTest
                % Only take largest single cluster to avoid outliers
                Clusters = swa_ClusterTest(double(Channels), Info.Recording.ChannelNeighbours, 0.01);
                
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
            end
            
            % Cross correlate with the peak (prototypical channel)
            % only calculate if ref correlation is not 'very high'
            
            % find the prototypical channel
            [~, negative_peak_index] = min(SW(nSW).Channels_NegAmp);
            
            if maxCC(negative_peak_index) < (Info.Parameters.Channels_Threshold + 1) / 2
                maxDelay = maxID(negative_peak_index) - win;
                maxData = Data.Filtered(negative_peak_index,...
                    SW(nSW).Ref_PeakInd - win + maxDelay : SW(nSW).Ref_PeakInd + win + maxDelay);
                
                cc = swa_xcorr(maxData, shortData, win);
            
                % find the maximum correlation and location
                [maxCC, maxID]      = max(cc,[],2);
                
                % channels with correlation above threshold
                Channels(maxCC > Info.Parameters.Channels_Threshold) = true;
                
            end
            
            % TODO: Test for type 1 or 2 waves
            % ```````````````````````````````
            % TODO: Processing for multi-peak waves
            % `````````````````````````````````````

            % eliminate the potentially false channels from the cluster test
            % in the negative amplitudes variable 
            SW(nSW).Channels_NegAmp(~Channels) = nan;

            
            % Delay Calculation
            % `````````````````
            SW(nSW).Travelling_Delays = nan(length(Info.Electrodes),1);
            SW(nSW).Travelling_Delays(Channels)...
                = maxID(Channels) - min(maxID(Channels));
            
            SW(nSW).Channels_Globality  = sum(Channels)/length(Channels)*100;
            SW(nSW).Channels_Active 	= Channels;
        end


    % Thresholding Method
    % ^^^^^^^^^^^^^^^^^^^    
    case 'threshold'
        % check for peak to peak criteria
        if isempty(Info.Parameters.Ref_Peak2Peak)
            Info.Parameters.Ref_Peak2Peak = ...
                abs(Info.Parameters.Ref_NegAmpMin) * 1.75;
        end
        
        for nSW = 1:length(SW)
            % start the waitbar
            if flag_progress
                waitbar(nSW/length(SW),WaitHandle,sprintf('Slow Wave %d of %d',nSW, length(SW)))
            end

            % check that the search window doesn't cross data start or end
            % TODO: improve check as these may be legitimate slow waves
            if SW(nSW).Ref_PeakInd - win < 1 || SW(nSW).Ref_PeakInd + win * 3 > Info.Recording.dataDim(2)
                ToDelete(end+1) = nSW;
                continue
            end

            % only take the relevant data in the window
            shortData   = Data.Filtered(:,SW(nSW).Ref_PeakInd - win ...
                        : SW(nSW).Ref_PeakInd + win);
                    
            % Minimum amplitude threshold for channels
            [SW(nSW).Channels_NegAmp, minChId] = min(shortData,[],2);
            SW(nSW).Channels_Active = SW(nSW).Channels_NegAmp < ...
                -mean(Info.Parameters.Ref_AmplitudeAbsolute) * Info.Parameters.Channels_Threshold;
           
            % Peak to Peak Check
            % for peak to peak check we need a longer window after the peak
            shortData   = Data.Filtered(:,SW(nSW).Ref_PeakInd - win ...
                        : SW(nSW).Ref_PeakInd + win * 3);
            
            % pre-allocate the positive amplitudes
            posPeakAmp = nan(size(shortData, 1), 1);
            % find the positive peak after the negative peak
            for nCh = find(SW(nSW).Channels_Active == 1)'
                posPeakAmp(nCh) = max(shortData(nCh, minChId(nCh):end));
            end
            SW(nSW).Channels_Active(posPeakAmp - SW(nSW).Channels_NegAmp < ...
                Info.Parameters.Ref_Peak2Peak * Info.Parameters.Channels_Threshold) = false;

            % TODO: slope check
            
            % Wavelength Check
            % Not performed as some channels do not actually cross zero but
            % show all other characteristics of the slow wave
            
            % eliminate channels in NegAmp with sub-threshold amplitude
            SW(nSW).Channels_NegAmp(~SW(nSW).Channels_Active) = nan;
            
            % Sufficient Channels Check (more than 0)
            if sum(SW(nSW).Channels_Active) == 0
                ToDelete(end+1) = nSW;
                continue
            end
            
            % Delay Calculation
            % Using negative peak id
            SW(nSW).Travelling_Delays = nan(length(Info.Electrodes),1);
            SW(nSW).Travelling_Delays(SW(nSW).Channels_Active)...
                = minChId(SW(nSW).Channels_Active) - min(minChId(SW(nSW).Channels_Active));
            
            % count the number of active channels
            SW(nSW).Channels_Globality = sum(SW(nSW).Channels_Active)...
                / length(SW(nSW).Channels_Active) * 100;            
        end
            
end

% close the wait bar
if flag_progress
    delete(WaitHandle)       % DELETE the waitbar; don't try to CLOSE it.
end

% delete the bad waves
fprintf(1, 'Information: %d slow waves were removed due insufficient criteria \n', length(ToDelete));
SW(ToDelete) = [];
