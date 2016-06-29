function [Data, Info, ST] = swa_FindSTChannels(Data, Info, ST, flag_progress)
% find saw-tooth waves in individual channels
% TODO: develop a method without using wavelets at the channel level

if flag_progress
    fprintf(1, 'Analysis: Finding Saw-Tooth Waves in Individual Channels... \n');
end
    
% -- Calculate CWT Waves -- %
FreqRange   = Info.Parameters.CWT_hPass : Info.Parameters.CWT_lPass;
Scale_theta = (centfrq('morl')./FreqRange) * Info.Recording.sRate;

% initialise the wavelet data (single to save memory)
Channels_Theta = single(zeros(size(Data.Raw)));

% calculate the wavelet coefficients for each channel on a loop (unfortunately)
if flag_progress; swa_progress_indicator('initialise', 'Calculating wavelets'); end
for n = 1 : size(Data.Raw, 1)
    if flag_progress; swa_progress_indicator('update', n, size(Data.Raw, 1)); end
    Channels_Theta(n, :) = mean(cwt(Data.Raw(n, :), Scale_theta, 'morl'));
end

%% -- Find corresponding channels from the reference wave -- %%
Window = round(Info.Parameters.Channels_WinSize * Info.Recording.sRate);
for nST = 1:length(ST)

    % calculate the range of segment data
    range = (ST(nST).CWT_NegativePeak - Window) : ...
        (ST(nST).CWT_NegativePeak + Window);
       
    % Negative Theta Amplitude Criteria (with channel maximum criteria)
    [Ch_Min, Ch_Id] = min(Channels_Theta(:, range), [], 2);
    ST(nST).Channels_Active = false(size(Channels_Theta, 1), 1);
    ST(nST).Channels_Active(...
        Ch_Min < -Info.Parameters.CWT_AmpThresh(ST(nST).Ref_Region(1)) / 2 ...
        * Info.Parameters.Channel_Adjust ...
        & Ch_Min > -Info.Parameters.CWT_AmpThresh(ST(nST).Ref_Region(1)) * 5) ...
        = true;
    
    % Eliminate channels with delay of 1 since they are most likely just
    % the minimum on a positive slope of a previous wave...
    ST(nST).Channels_Active(Ch_Id == 1) = false;
        
    % Calculate Parameters
    ST(nST).Channels_Globality = sum(ST(nST).Channels_Active) / size(Channels_Theta, 1) * 100;
    
    % Calculate the peak to peak amplitude in the raw data
    % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    % extract segment of interest from raw data(and detrend)
    data_segment = detrend(Data.Raw(:, range)')';
    
    % smooth the raw data with a 5 sample window
    smoothing_window = floor(0.025 * Info.Recording.sRate);
    s_data_segment = smooth(data_segment', smoothing_window)';
    s_data_segment = reshape(s_data_segment, size(data_segment'))';
    
    % find the minimum amplitude in the raw data
    local_minimum = min(s_data_segment(ST(nST).Channels_Active, :), [], 2);
    % find the maximum amplitude in the raw data after the minimum
    local_maxima = max(s_data_segment(ST(nST).Channels_Active, ...
        Window : end), [], 2);
    
    % calculate peak to peak
    ST(nST).Channels_Peak2PeakAmp = nan(size(Channels_Theta, 1), 1);
    ST(nST).Channels_Peak2PeakAmp(ST(nST).Channels_Active) = ...
        local_maxima - local_minimum;
        
    % Save maxima and minima in the raw data
    ST(nST).Channels_NegativeMax = nan(size(Channels_Theta, 1), 1);
    ST(nST).Channels_NegativeMax(ST(nST).Channels_Active) = local_minimum;
    ST(nST).Channels_PositiveMax = nan(size(Channels_Theta, 1), 1);
    ST(nST).Channels_PositiveMax(ST(nST).Channels_Active) = local_maxima;
    
    % delay is calculated as timing of local minima in the wavelet
    ST(nST).Travelling_Delays = nan(size(Channels_Theta, 1), 1);
    ST(nST).Travelling_Delays(ST(nST).Channels_Active) = Ch_Id(ST(nST).Channels_Active)...
        - min(Ch_Id(ST(nST).Channels_Active));
        
end
