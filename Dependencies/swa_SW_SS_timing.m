function [cross_cor_all] = SSa_SS_SS_timing(Data, Info, SS)
% load a spindle results file and computes the cross-correlation between 
% power in the spindle range and slow wave amplitude

% set parameters
s_rate = Info.Recording.sRate;
phaseFreq = [0.5, 3];
ampFreq = [11, 16];
window_length = 0.5;
segment_window = window_length * s_rate;
time_range = linspace(0, 3, segment_window * 3);

% spindle range
% ^^^^^^^^^^^^^
% Extract envelope for amplitude frequency band using Hilbert transform
order = round(3*(s_rate/ampFreq(1)));
fir1Coef = fir1(order,[ampFreq(1),ampFreq(2)]./(s_rate/2));
ampSignal = filtfilt(fir1Coef, 1, Data.Raw')';
% get amplitude envelope
Amp = abs(hilbert(ampSignal'))';
% PhaseEnvlp = angle(hilbert(zscore(Amp')))';

% slow wave range
% ^^^^^^^^^^^^^^^
% Extract phase for phase frequency band using Hilbert transform
order = round(3*(s_rate/phaseFreq(1)));
fir1Coef = fir1(order,[phaseFreq(1),phaseFreq(2)]./(s_rate/2));
phaseSignal = filtfilt(fir1Coef, 1, Data.Raw')';
% Phase = angle(hilbert(phaseSignal'))';

% check for too early or too late spindles
spindle_start = [SS.Ref_Start];
spindle_end = [SS.Ref_End];
SS(spindle_start < [segment_window * 2]) = [];
SS(spindle_end > [size(Data.Raw, 2) - segment_window]) = [];

% pre-allocate
cross_cor_all = nan(size(Data.Raw, 1),  length(time_range) * 2 - 1);
% loop for each channel
SSa_progress_indicator('initiate', 'channels processed');
for nCh = 1 : size(Data.Raw, 1)
    SSa_progress_indicator('update', nCh, size(Data.Raw, 1));
    % loop for each spindle found
    SS_cross_cor = nan(length(SS), length(time_range) * 2 - 1);
    for n = 1 : length(SS)
        
        % extract data segments
        sample_range = SS(n).Ref_Start - 2 * segment_window ...
            : SS(n).Ref_Start + segment_window - 1;
        
        slow_segment = phaseSignal(nCh, sample_range);
        spindle_segment = Amp(nCh, sample_range);
%         slow_segment = sin(Phase(nCh, sample_range));
%         spindle_segment = sin(PhaseEnvlp(nCh, sample_range));
        
        %     figure; plot(phaseSignal(nCh, sample_range)); hold on; plot(ampSignal(nCh, sample_range)); plot(Data.Raw(nCh, sample_range));
        %     figure; plot(Amp(nCh, sample_range)); hold on; plot(phaseSignal(nCh, sample_range));
        %     figure; plot(slow_segment); hold on; plot(spindle_segment);
        
        % cross-correlate slow phase and spindle amplitude phase
        SS_cross_cor(n, :) = xcorr(slow_segment, spindle_segment, 'coeff');
        
%         figure; plot([-fliplr(time_range), time_range], [0, SS_cross_cor(n, :)])
        
    end
    
    cross_cor_all(nCh, :) = mean(SS_cross_cor);
    
end

% figure; plot([-fliplr(time_range), time_range], [zeros(size(Data.Raw, 1), 1), cross_cor_all])

% csc_Topoplot(cross_cor_all(:, 210), Info.Electrodes)