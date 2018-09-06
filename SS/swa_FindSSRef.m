function [Data, Info, SS] = swa_FindSSRef(Data, Info)
% Automatic spindle detection on a reference channel using continuous 
% wavelet transform

% The algorithm used is built on the one used by Wamsley et al 2012 which 
% was the highest rated automatic detection algorithm in a comparison by
% Warby et al 2014 (NatureMethods). 
% Here this is improved upon by: using a 
% - shorter default minimum detection window (300ms instead of 500ms), a 
%   change which puts the method ahead of non-expert consensus in the study
%   by Warby et al
% - using a dynamic threshold based on the standard deviation above the
%   mean in the power spectrum (and not just the mean), which would
%   stabalise the results across different nights/participants
% - finding the true start of the spindle by calculating the lowest trough
%   in the power spectrum prior to passing the threshold (end as well)
% - performing an additional wavelet transform to determine whether the 
%   spindle is best classified as a slow or fast variant

% set breakpoint to look for specific spindle
%         if spindle_start(n) > 38000 & spindle_start(n) < 38500
%             x = 1;
%         end

%% Initialise the SS Structure
SS = struct(...
    'Ref_Region',               [],...
    'Ref_Start',                [],...
    'Ref_End',                  [],...
    'Ref_PeakFreq',             [],...
    'Ref_PeakPower',            [],...
    'Ref_PeakWavelet',          [],...
    'Ref_NegativePeak',         [],...
    'Ref_PositivePeak',         [],...
    'Ref_Peak2Peak',            [],...
    'Ref_Length',               [],...
    'Ref_NumberOfWaves',        [],...
    'Ref_Symmetry',             [],...
    'Channels_Active',          [],...    
    'Channels_Globality',       [],...
    'Channels_Power',           [],... % peak to peak amplitude (wavelet) | FFT power (power method)
    'Channels_PowerRatio',      [],... % FFT power compared to its neighbour frequencies
    'Channels_PeakFreq',        [],...
    'Travelling_Delays',        []);

% intiialise spindle count
SS_count  = 0;

%% Info defaults
if ~isfield(Info, 'Parameters')
    % get general defaults
    Info = swa_getInfoDefaults(Info, 'SS');
    fprintf('Information: No parameters found in Info, using defaults\n');
end

% Wavelet Parameters
waveName = Info.Parameters.Wavelet_name;
wavelet_center = centfrq(waveName);
freqCent = Info.Parameters.Filter_band(1) : 0.5 : Info.Parameters.Filter_band(2);
scales = wavelet_center./(freqCent./ Info.Recording.sRate);

% Loop for each Reference Wave
for ref_wave = 1 : size(Data.SSRef, 1)
    
    % how many spindles have been detected?
    if isempty(SS)
        original_count = 0;
    else
        original_count = length(SS);
    end

    % --Continuous Wavelet Transform -- %
    cwtCoeffs = cwt(Data.SSRef(ref_wave, :), scales, waveName);
    cwtCoeffs = abs(cwtCoeffs.^ 2);
    cwtPower = nanmean(cwtCoeffs);
    
    % smooth the wavelet power
    window = ones(round(Info.Recording.sRate * Info.Parameters.Filter_Window), 1)...
        / round(Info.Recording.sRate * Info.Parameters.Filter_Window);
    Data.CWT(ref_wave, :) = filtfilt(window, 1, cwtPower);  
    
    % -- Threshold crossings -- %
    % if no soft threshold specified make 50% of first
    if length(Info.Parameters.Ref_AmplitudeRelative) == 1
        Info.Parameters.Ref_AmplitudeRelative(2) = ...
            Info.Parameters.Ref_AmplitudeRelative(1) * 0.5;
    end
    
    % Calculate power threshold criteria
    if strcmp(Info.Parameters.Ref_AmplitudeCriteria, 'relative')
                
        switch Info.Parameters.Ref_AmplitudeMetric
            case 'mean'
                % calculate the standard deviation from the mean
                std_wavelet = nanstd(Data.CWT(ref_wave, :), 1);
                
                % calculate the absolute threshold for that canonical wave
                Info.Parameters.Ref_AmplitudeAbsolute(ref_wave) = ...
                    (std_wavelet * Info.Parameters.Ref_AmplitudeRelative(1))...
                    + mean(Data.CWT(ref_wave, :));
                threshold_hard = Info.Parameters.Ref_AmplitudeAbsolute(ref_wave);
                threshold_soft = (std_wavelet * Info.Parameters.Ref_AmplitudeRelative(2))...
                    + mean(Data.CWT(ref_wave, :));
                
            case 'median'
                % calculate the standard deviation from the mean
                std_wavelet = mad(Data.CWT(ref_wave, :), 1);
                
                % calculate the absolute threshold for that canonical wave
                Info.Parameters.Ref_AmplitudeAbsolute(ref_wave) = ...
                    (std_wavelet * Info.Parameters.Ref_AmplitudeRelative(1))...
                    + median(Data.CWT(ref_wave, :));
                threshold_hard = Info.Parameters.Ref_AmplitudeAbsolute(ref_wave);
                % TODO: save soft thresholds for later standardisation of absolute thresholds
                threshold_soft = (std_wavelet * Info.Parameters.Ref_AmplitudeRelative(2))...
                    + median(Data.CWT(ref_wave, :));
        end
    else
        % check if single or multiple defined power values
        if ~length(Info.Parameters.Ref_AmplitudeAbsolute) == size(Data.SSRef, 1)
            % repeat single threshold
            Info.Parameters.Ref_AmplitudeAbsolute = ...
                repmat(Info.Parameters.Ref_AmplitudeAbsolute, 1, size(Data.SSRef, 1));
        end
        % define hard and soft absolute thresholds
        threshold_hard = Info.Parameters.Ref_AmplitudeAbsolute(ref_wave);
        
        % soft thresholds will not be identical as those calculated above
        % since the median of the signal is disregarded here, so the ratio
        % of the selected medians is used as a percentage of absolute
        threshold_soft = Info.Parameters.Ref_AmplitudeAbsolute(ref_wave) / ...
            [Info.Parameters.Ref_AmplitudeRelative(1) / Info.Parameters.Ref_AmplitudeRelative(2)];
    end
    
    % -- Get the times where power data is above high threshold --%
    signData = sign(Data.CWT(ref_wave, :) - threshold_hard);
    power_start = find(diff(signData) == 2);
    power_end = find(diff(signData) == -2);
    
    % Check for earlier start than end
    if power_end(1) < power_start(1)
        power_end(1) = [];
    end
    
    % Check for end after start
    if length(power_start) > length(power_end)
        power_start(end) = [];
    end
    
    % Check Soft Minimum Length (30% less than actual minimum) %
    SS_lengths = power_end - power_start;
    minimum_length = (Info.Parameters.Ref_WaveLength(1) / 1.3) * Info.Recording.sRate;
    
    % remove all potentials under the soft minimum length
    power_start(SS_lengths < minimum_length) = [];
    power_end(SS_lengths < minimum_length) = [];
    
    % check softer threshold for actual start of spindle
    spindle_start = nan(length(power_start), 1);
    spindle_end = nan(length(power_start), 1);
    % above soft threshold points
    signData = sign(Data.CWT(ref_wave, :) - threshold_soft);
    soft_start = find(diff(signData) == 2);
    soft_end = find(diff(signData) == -2);
    
    % loop over each (potential) spindle and find "true" start
    for n = 1 : length(power_start)
        % advance/delay each start/end based on soft threshold
        advance = min(power_start(n) - soft_start(soft_start < power_start(n)));
        
        % check for very early spindle with no soft start
        if isempty(advance)
            spindle_start(n) = 1;
        else
            spindle_start(n) = power_start(n) - advance;
        end
        
        % look for soft threshold cross after hard threshold
        delay = min(soft_end(soft_end > power_end(n)) - power_end(n));        
        % check that power crosses low threshold before recording end
        if isempty(delay)
            spindle_end(n) = length(signData);
        else
            spindle_end(n) = power_end(n) + delay;
        end
    end
    
    % make sure spindle starts are unique 
    % NOTE: could have been double hard crossing without soft crossing
    spindle_start = unique(spindle_start);
    spindle_end = unique(spindle_end);
    
    % re-check lengths
    if length(spindle_end) > length(spindle_start)
        spindle_end(end) = [];
    end
    
    % Check Hard Minimum Length %
    SS_lengths = spindle_end - spindle_start;
    minimum_length = Info.Parameters.Ref_WaveLength(1) * Info.Recording.sRate;
    
    spindle_start(SS_lengths < minimum_length) = [];
    spindle_end(SS_lengths < minimum_length) = [];
    SS_lengths(SS_lengths < minimum_length) = [];
    
    % Check Maximum Length %
    maximum_length = Info.Parameters.Ref_WaveLength(2) * Info.Recording.sRate;
    spindle_start(SS_lengths > maximum_length) = [];
    spindle_end(SS_lengths > maximum_length) = [];
    SS_lengths(SS_lengths > maximum_length) = []; 
    
    % Calculate slope of reference data
    slope_canonical  = [0 diff(Data.SSRef(ref_wave, :))];
       
    % Loop through each spindle found
    for n = 1 : length(spindle_start)
        
        % -- Find the local peaks and troughs -- %
        % Calculate the slope of the original wave
        slope_SS  = slope_canonical(:, spindle_start(n) : spindle_end(n));
        
        % Find all the peaks, both positive and negative
        peak_indices = find(abs(diff(sign(slope_SS))) == 2);
        peak_amplitudes = Data.SSRef(ref_wave,...
            spindle_start(n) - 1 + peak_indices);
        
        % find the maximum peak to peak difference
        [peak2peak, max_indice] = max(abs(diff(peak_amplitudes)));
        
        % -- check for the number of individual waves -- %
        if length(peak_amplitudes) < Info.Parameters.Ref_MinWaves * 2
            continue;
        end
        
        % -- find peak frequency -- %
        % extract spindle segment with a data buffer
        sample_range = spindle_start(n) - floor(Info.Recording.sRate) / 4 : ...
                spindle_end(n) + floor(Info.Recording.sRate) / 4;
        sample_range(sample_range < 1) = [];
        sample_range(sample_range > length(Data.SSRef(ref_wave, :))) = [];
        spindle_segment = Data.SSRef(ref_wave, sample_range);
        
        % calculate the power spectrum using pwelch
        [spectrum_segment, freq_range] = pwelch(spindle_segment, ...
            length(spindle_segment), ...
            0, ...
            length(spindle_segment),...
            Info.Recording.sRate);
        
        % find the peak in the spindle range
        spindle_range = freq_range >= Info.Parameters.Filter_band(1) & ...
            freq_range <= Info.Parameters.Filter_band(2);
        [peak_power, max_ind] = max(spectrum_segment(spindle_range));
        peak_frequency = Info.Parameters.Filter_band(1) + (max_ind - 1) * 0.5;
        
        % check neighbouring power to ensure its spindle specific
        neighbour_range = ...
            freq_range >= Info.Parameters.Filter_band(1) - Info.Parameters.Filter_checkrange & ...
            freq_range < Info.Parameters.Filter_band(1) | ...
            freq_range > Info.Parameters.Filter_band(2) & ...
            freq_range <= Info.Parameters.Filter_band(2) + Info.Parameters.Filter_checkrange;
            
        % mean power of each range
        if mean(spectrum_segment(spindle_range)) < ...
            mean(spectrum_segment(neighbour_range)) * Info.Parameters.Ref_NeighbourRatio
            continue
        end
        
        
        % -- calculate the power using the wavelet -- %
        spindle_wavelet = Data.CWT (ref_wave, sample_range);
        peak_wavelet = max(spindle_wavelet);

        
        % -- Save Wave to Structure -- %
        % Check if the SS has already been found in another reference channel
        % TODO: double check this is still some doubling occurring
        if ref_wave > 1
                       
            % Find mid point of all waves calculated so far
            all_starts = [SS.Ref_Start];
            all_ends = [SS.Ref_End];
            
            % check whether current spindle is between start and end of another
            SS_indice = find((mean([all_starts; all_ends]) > spindle_start(n) ...
                    & mean([all_starts; all_ends]) < spindle_end(n)) ...
                    | (mean([spindle_start(n); spindle_end(n)]) > all_starts ...
                    & mean([spindle_start(n); spindle_end(n)]) < all_ends));
            
            % sometimes new spindle crosses two previously found ones
            % then we want to merge the two together
            if length(SS_indice) > 1
                earlier_spindle = SS_indice(1);
                
                % take the largest amplitude and longest durations                
                SS(earlier_spindle).Ref_Region = unique([SS(SS_indice).Ref_Region]);
                
                SS(earlier_spindle).Ref_Start = min([SS(SS_indice).Ref_Start]);
                SS(earlier_spindle).Ref_End = max([SS(SS_indice).Ref_End]);

                SS(earlier_spindle).Ref_NegativePeak = min([SS(SS_indice).Ref_NegativePeak]);
                SS(earlier_spindle).Ref_PositivePeak = max([SS(SS_indice).Ref_PositivePeak]);
                SS(earlier_spindle).Ref_Peak2Peak = max([SS(SS_indice).Ref_Peak2Peak]);
                SS(earlier_spindle).Ref_PeakFreq = mean([SS(SS_indice).Ref_PeakFreq]);
                SS(earlier_spindle).Ref_PeakPower =  max([SS(SS_indice).Ref_PeakPower]);
                SS(earlier_spindle).Ref_PeakPower =  max([SS(SS_indice).Ref_PeakWavelet]);
                % NOTE: if merged number of waves and symmetry is no longer easy to calculate
                
                % delete the other spindle(s)
                SS(SS_indice(2:end)) = [];
                SS_count = SS_count - length(SS_indice(2:end));
                SS_indice(2:end) = [];
            end
                
            % add new spindle parameters to the SS structure
            if ~isempty(SS_indice)
                % Check which region has the bigger P2P wave...
                if peak2peak > SS(SS_indice).Ref_Peak2Peak
                    % If the new region does then overwrite previous data with larger reference
                    SS(SS_indice).Ref_Region          =      [ref_wave, SS(SS_indice).Ref_Region];
                    SS(SS_indice).Ref_NegativePeak    =      min(peak_amplitudes);
                    SS(SS_indice).Ref_PositivePeak    =      max(peak_amplitudes);
                    SS(SS_indice).Ref_Peak2Peak       =      peak2peak;
                    SS(SS_indice).Ref_PeakFreq        =      peak_frequency;
                    SS(SS_indice).Ref_PeakPower       =      peak_power;
                    SS(SS_indice).Ref_PeakWavelet     =      peak_wavelet;
                    SS(SS_indice).Ref_NumberOfWaves   =      length(peak_amplitudes)/2;
                    SS(SS_indice).Ref_Symmetry        =      max_indice/(length(peak_amplitudes)-1);
                else
                    % if the previous spindle is larger just add the reference
                    SS(SS_indice).Ref_Region(end + 1) = ref_wave;
                end
                
                % always take the earliest and latest out of the two for duration
                SS(SS_indice).Ref_Start = min(spindle_start(n), SS(SS_indice).Ref_Start);
                SS(SS_indice).Ref_End = max(spindle_end(n), SS(SS_indice).Ref_End);
                SS(SS_indice).Ref_Length = SS(SS_indice).Ref_End - SS(SS_indice).Ref_Start;
                
                % skip adding new spindle with these parameters and go to the next
                continue;
            end
        end
        
        % if no previous spindle matches create a new one
        SS_count = SS_count + 1;

        SS(SS_count).Ref_Region          =      ref_wave;
        SS(SS_count).Ref_NegativePeak    =      min(peak_amplitudes);
        SS(SS_count).Ref_PositivePeak    =      max(peak_amplitudes);
        SS(SS_count).Ref_Peak2Peak       =      peak2peak;
        SS(SS_count).Ref_PeakFreq        =      peak_frequency;
        SS(SS_count).Ref_PeakPower       =      peak_power;
        SS(SS_count).Ref_PeakWavelet     =      peak_wavelet;
        SS(SS_count).Ref_Start           =      spindle_start(n);
        SS(SS_count).Ref_End             =      spindle_end(n);
        SS(SS_count).Ref_Length          =      SS_lengths(n);
        SS(SS_count).Ref_NumberOfWaves   =      length(peak_amplitudes) / 2;
        SS(SS_count).Ref_Symmetry        =      max_indice/(length(peak_amplitudes) - 1);

    end
    
    % brief report of the spindles found
    if ref_wave == 1
        fprintf(1, 'Information: %d spindle bursts found in reference wave \n', length(SS));
    else
        fprintf(1, 'Information: %d spindle bursts added from region %d \n', length(SS) - original_count, ref_wave);
    end
    
end

% Sort SS structure by timing of main peak
midpoint_SS = [SS.Ref_Start];
[~, sort_indices] = sort(midpoint_SS);
SS = SS(sort_indices);