

%% Alternative Calculation of the Slow Wave Slope
% as drop in uV per second of the entire downward, verus upward portion

% calculate the slope of the waves using the mean
down_durations = ([SW.Ref_PeakInd] - [SW.Ref_DownInd]) / Info.Recording.sRate;
up_durations = ([SW.Ref_UpInd] - [SW.Ref_PeakInd]) / Info.Recording.sRate;

% find the wave amplitude at the start and end (may not be the zero-crossing)
amp_at_down = Data.SWRef([SW.Ref_DownInd]);
amp_at_up = Data.SWRef([SW.Ref_UpInd]);

% find actual amplitude differences between these points
down_amp_diff = abs([SW.Ref_PeakAmp] - amp_at_down);
up_amp_diff = abs(amp_at_up - [SW.Ref_PeakAmp]);

% new calculation for slopes
alt_neg_slope = [down_amp_diff ./ down_durations] * -1;
alt_pos_slope = up_amp_diff ./ up_durations;

%% plot the difference
g = gramm(...
    'x', alt_neg_slope, ...
    'y', [SW.Ref_NegSlope]);
g.geom_point();
g.stat_smooth();
g.draw();

figure();
g = gramm(...
    'x', alt_pos_slope, ...
    'y', [SW.Ref_PosSlope]);
g.geom_point();
g.stat_smooth();
g.draw();