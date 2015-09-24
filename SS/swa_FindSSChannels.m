function [Data, Info, SS] = swa_FindSSChannels(Data, Info, SS)
% Automatic spindle detection on all channels after initial spindles have 
% been detected in a reference channel 

% Check for previously filtered data
if Info.Parameters.Filter_Apply
    if isfield(Data, 'Filtered')
        % if the field exists but is empty then filter it
        if isempty(Data.Filtered)
            fprintf(1,'Calculation: Filtering Data. \n');
            Data.Filtered = swa_filter_data(Data.Raw, Info);
        end
        % if the field does not exist, filter the raw data
    else
        fprintf(1,'Calculation: Filtering Data. \n');
        Data.Filtered = swa_filter_data(Data.Raw, Info);
    end
end

% parameters for continuous wavelet transform
freq_range = Info.Parameters.Filter_hPass(1) : 0.5 : Info.Parameters.Filter_lPass(2);
full_scale = (centfrq('morl')./ freq_range) * Info.Recording.sRate;

% filter window
power_window = ones((Info.Parameters.Filter_Window * Info.Recording.sRate), 1) /...
    (Info.Parameters.Filter_Window * Info.Recording.sRate);
    
% calculate cwt for each channel
cwtData = zeros(size(Data.Raw));
swa_progress_indicator('initialise', 'channel wavelets');
for n = 1 : size(Data.Raw, 1)
    swa_progress_indicator('update', n, size(Data.Raw,1));
    cwtData(n, :) = mean(cwt(Data.Raw(n, :), full_scale, 'morl'));
end

% calculate the power of each cwt
power_data = cwtData.^ 2;
power_data = filter(power_window, 1, power_data')';

% calculate individual channel thresholds
if strcmp(Info.Parameters.Ref_AmplitudeCriteria, 'relative')
    std_wavelets = mad(power_data', 1)';
    thresholds = (std_wavelets.* Info.Parameters.Ref_AmplitudeRelative * ...
        Info.Parameters.Channels_Threshold) + median(power_data, 2);
else
    thresholds = repmat(Info.Parameters.Ref_AmplitudeAbsolute(1) *  Info.Parameters.Channels_Threshold,...
        size(Data.Raw, 1), 1);
end

% when and for how long does the power cross the threshold
sign_data = sign(power_data - repmat(thresholds, [1, size(power_data, 2)]));
min_length = (Info.Parameters.Ref_WaveLength(1) / 1.3) * Info.Recording.sRate;
    
% time around the reference wave for other channels
sample_window = round(Info.Parameters.Channels_WinSize * Info.Recording.sRate);

% -- Find corresponding channels from the reference wave -- %
swa_progress_indicator('initialise', 'finding spindles in channels');
wave_to_delete = [];

for nSS = 1 : length(SS)
    swa_progress_indicator('update', nSS, length(SS));
    
    % calculate the sample range
    range = SS(nSS).Ref_Start - sample_window : ...
        SS(nSS).Ref_End + sample_window; 
    
    % check for valid range
    range(range <= 0) = [];
    range(range > size(Data.Raw, 2)) = [];
    
    % extract short_data
    short_data = power_data(:, range);

    % Maximum power and duration criteria
    short_sign = sign_data(:, range);
    positive_channels = sum(short_sign > 0, 2) > min_length * Info.Parameters.Channels_Threshold;
    
    % find the time of the peak of the power data
    short_data = short_data(positive_channels, :);
    [~, maxID] = max(short_data, [], 2); 
    
    % -- Calculate peak to peak -- %
    % find the slopes of the raw data
    if Info.Parameters.Filter_Apply
        slope_data  = diff(Data.Filtered(positive_channels, range), 1, 2);
    else
        slope_data  = diff(Data.Raw(positive_channels, range), 1, 2);
    end
    
    % -- Find all the peaks, both positive and negative -- %
    peak2peak = nan(sum(positive_channels), 1);
    channel_indices = find(positive_channels);
    for ch = 1 : size(slope_data, 1)
        % peak indices for that channel
        peak_indices = find(abs(diff(sign(slope_data(ch, :)), 1, 2)));
        
        % get the largest amplitude
        peakAmp = Data.Raw(channel_indices(ch),...
            SS(nSS).Ref_Start + peak_indices);
        
        % if a channel has less than 3 peaks, delete it
        if length(peakAmp) < 3
            peak2peak(ch, :) = nan;
            positive_channels(channel_indices(ch)) = false;
            continue;
        end
        peak2peak(ch, :) = max(abs(diff(peakAmp)));
    end
    
    % continue if no channels are left after duration and peak2peak checks
    if sum(positive_channels) == 0
        wave_to_delete(end+1) = nSS; %#ok<AGROW>
        continue
    end
    
    % -- Save to SS structure -- %
    % pre-allocate using nans
    SS(nSS).Channels_Peak2PeakAmp = nan(length(Info.Electrodes), 1);
    SS(nSS).Channels_Peak2PeakAmp(positive_channels) = peak2peak;
    
    % save remaining channels to structure
    SS(nSS).Channels_Active = positive_channels;
    SS(nSS).Channels_Globality  = sum(SS(nSS).Channels_Active)...
        / length(SS(nSS).Channels_Active) * 100;
         
    % Find delays based on time of maximum power
    SS(nSS).Travelling_Delays = nan(length(Info.Electrodes), 1);
    SS(nSS).Travelling_Delays(positive_channels) = maxID - min(maxID);
    
end

if ~isempty(wave_to_delete)
    fprintf(1, 'Information: %d spindle(s) were removed due insufficient criteria \n', length(wave_to_delete));
    SS(wave_to_delete)=[];
end
