function [peak_freq, wavelet_transform, freq_range] = swa_get_peak_freq(Data, Info, SS, flag_plot)
% get the peak frequency of the waveform

% currently only works for spindles

% check inputs
if nargin < 3
    error('Requires Data, Info, and SS structures');
elseif nargin < 4
    flag_plot = false;
end

% define trial parameters
window_time = 0.5; % HARD_CODED_VALUE
window_samples = floor(window_time * Info.Recording.sRate);
time_zero = floor(window_time *  Info.Recording.sRate);

% look for spindles that are out of range
if isfield(SS, 'Ref_Start') % check for wave type (now always spindles)
    SS([SS.Ref_Start] - window_samples < 1) = [];
    SS([SS.Ref_Start] + window_samples > Info.Recording.dataDim(2)) = [];
end

% run dummy example for pre-allocation
range = SS(1).Ref_Start - window_samples ...
        : SS(1).Ref_Start + window_samples * 2;
[wt, freq_range] = cwt(Data.SSRef(3, range), 'bump', Info.Recording.sRate);
spindle_range = ...
    freq_range > Info.Parameters.Filter_band(1) - Info.Parameters.Filter_checkrange & ...
    freq_range < Info.Parameters.Filter_band(2) + Info.Parameters.Filter_checkrange;
spindle_freqs = freq_range(spindle_range);
    
% pre-allocate
num_canonical = size(Data.SSRef, 1);
wavelet_transform = nan(size(wt, 1), size(wt, 2), num_canonical, length(SS));
peak_freq = nan(length(SS), num_canonical);

% loop for each spindle
for n = 1 : length(SS)
    
    % define the time range around the start
    range = SS(n).Ref_Start - window_samples ...
        : SS(n).Ref_Start + window_samples * 2;
       
    % run for each reference wave
    for n_canon = 1 : num_canonical
        segment_data = Data.SSRef(n_canon, range);
        wavelet_transform(:, :, n_canon, n) = ...
            cwt(segment_data, 'bump', Info.Recording.sRate);
        
        % get peak
        [~, max_ind] = max(max(abs(...
            wavelet_transform(spindle_range, time_zero : end, n_canon, n)), [], 2));
        peak_freq(n, n_canon) = spindle_freqs(max_ind);
        
    end
    
    
end

if flag_plot
    num_canonical = 3; 
    % plot the spindle time_freq
    time_range = linspace(-window_time, window_time * 2, size(wavelet_transform, 2));
    figure('color', 'w');
    axes('ylim', [10, 17]);
    contourf(time_range, freq_range(spindle_range),...
        mean(abs(wavelet_transform(spindle_range, :, num_canonical, :)), 4),...
        'edgecolor', 'none');
    colormap('hot');

    for n = 59
        nSS = n;
        figure('color', 'w');
        axes('ylim', [10, 17]);
        contourf(time_range, freq_range(spindle_range),...
            abs(wavelet_transform(spindle_range, :, num_canonical, nSS)),...
            'edgecolor', 'none');
        colormap('hot');
%         export_fig(gcf, ['sdz_wavelet_', num2str(n)], '-png', '-m3');
%         close(gcf);
    end

end