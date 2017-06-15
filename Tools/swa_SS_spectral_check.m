function [spectral_data, spectral_range] = swa_SS_spectral_check(Data, Info, SS, selected_regions, flag_plot)
% function computes the complete power spectrum over the dataset, then computes
% the spectrum without the detected spindles, and then only for detected spindles

% check inputs
if nargin < 4
    flag_plot = true;
end

if nargin < 4
    if strcmp(Info.Parameters.Ref_Method, 'grid')
        selected_regions = [2, 5, 8];
    else
        selected_regions = [1, 2, 3];
    end
end

% define p-welch parameters
window_length = Info.Recording.sRate;

% - all the data - %
% use p-welch to calculate the spectrum
[spectral_data.all_data, spectral_range] = pwelch(...
    Data.SSRef(selected_regions, :)' ,... % data (transposed to channels are columns)
    hanning(window_length) ,...    % window length with hanning windowing
    floor(window_length / 2) , ...   % overlap
    window_length ,...    % points in calculation (window length)
    Info.Recording.sRate);

% - spindle removed data - %
spindle_segments = false(size(Data.Raw, 2), 1);
for n = 1 : length(SS)
   
    spindle_segments(SS(n).Ref_Start : SS(n).Ref_End) = true;
    
end

% display data percentage
spindle_percent = sum(spindle_segments) / size(Data.Raw, 2) * 100;
fprintf(1, 'Information: spindle events occur in %0.1f%% of the data\n', spindle_percent);

% use p-welch to calculate the spectrum
[spectral_data.no_spindles, spectral_range] = pwelch(...
    Data.SSRef(selected_regions, ~spindle_segments)' ,... % data (transposed to channels are columns)
    hanning(window_length) ,...    % window length with hanning windowing
    floor(window_length / 2) , ...   % overlap
    window_length ,...    % points in calculation (window length)
    Info.Recording.sRate);

% - spindle only data - %
[spectral_data.spindle_only, spectral_range] = pwelch(...
    Data.SSRef(selected_regions, spindle_segments)' ,... % data (transposed to channels are columns)
    hanning(window_length) ,...    % window length with hanning windowing
    floor(window_length / 2) , ...   % overlap
    window_length ,...    % points in calculation (window length)
    Info.Recording.sRate);

% plot the differences
if flag_plot
    region_of_interest = 2;
    figure('color', 'w')
    axes('nextplot', 'add', ...
        'xlim', [0, 30]);
    plot(spectral_range, log10(spectral_data.all_data(:, region_of_interest)), ...
        'linewidth', 2);
    plot(spectral_range, log10(spectral_data.no_spindles(:, region_of_interest)), ...
        'linewidth', 2);
    plot(spectral_range, log10(spectral_data.spindle_only(:, region_of_interest)), ...
        'linewidth', 2);
    legend({'all_data', 'no_spindles', 'only_spindles'});
end




