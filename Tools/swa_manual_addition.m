function [SW, new_ind] = swa_manual_addition(Data, Info, SW,...
    sample_point, SW_type, flag_channels)
% wave parameters are calculated from manually selected sample point
% TODO: Channel detection still needs a lot of work

if nargin < 6
    flag_channels = true;
end

switch SW_type
    case 'SW'
        [SW, new_ind] = add_SW(Data, Info, SW, sample_point);
    case 'ST'
        [SW, new_ind] = add_ST(Data, Info, SW, sample_point, flag_channels);
end

function [SW, new_ind] = add_SW(Data, Info, SW, sample_point)

% define output in case of error
new_ind = [];

% quick check to make sure wave wasn't already found
time_tolerance = 0.600;
if min(abs([SW.Ref_PeakInd] - sample_point)) ...
        < time_tolerance * Info.Recording.sRate
    fprintf(1, 'Warning: Wave already found close to the selected point \n');
    return;
end

% extract a smaller segment of data
window = round(0.60 * Info.Recording.sRate);

Data_segment.SWRef = Data.SWRef(1, sample_point - window :sample_point + window);

% calculate the slope of the data
data_slope  = [0 diff(Data_segment.SWRef)];

% adjust to the nearest MNP
MNP  = find(diff(sign(data_slope)) == 2);
[~, min_ind] = min(Data_segment.SWRef(1, MNP));

sample_point = sample_point - window + MNP(min_ind);

% get all the data based on new sample point
Data_segment.Raw = double(Data.Raw(:, sample_point - window : sample_point + window));
Data_segment.SWRef = Data.SWRef(1, sample_point - window : sample_point + window);

% calculate the slope of the data
data_slope  = [0 diff(Data_segment.SWRef)];

switch lower(Info.Parameters.Ref_InspectionPoint)
    
    case 'mnp'
        % get the local minima and maxima (and eliminate small notches)
        [MNP, MPP] = swa_get_peaks(data_slope, Info, 1);

        if isempty(MNP) | isempty(MPP)
            fprintf(1, 'Warning: No local minima or maxima found in range\n');
            return;
        end
        
        % if more than 2 MPP and 1 MNP find the more extreme amplitudes
        [neg_amp, neg_id] = min(Data_segment.SWRef(MNP));
        MNP = MNP(neg_id);
        
        [~, pos_id] = max(Data_segment.SWRef(MPP(MPP < MNP)));
        MPP_before = MPP(pos_id);
        
        [~, pos_id] = max(Data_segment.SWRef(MPP(MPP > MNP)));
        MPP_after = MPP(pos_id + length(MPP(MPP < MNP)));
               
        % add the parameters to the end of SW structure
        SWid = length(SW) + 1;
        SW(SWid).Ref_Region    = [1];
        SW(SWid).Ref_DownInd   = MPP_before;
        SW(SWid).Ref_PeakInd   = MNP;
        SW(SWid).Ref_UpInd     = MPP_after;
        SW(SWid).Ref_PeakAmp   = neg_amp;
        SW(SWid).Ref_P2PAmp    = Data_segment.SWRef(MPP_after) - neg_amp;
        SW(SWid).Ref_NegSlope  = min(data_slope(1, MPP_before : MNP));
        SW(SWid).Ref_PosSlope  = max(data_slope(1, MNP : MPP_after));
        
    case 'zc'
        signData = sign(Data_segment.SWRef);
        DZC = find(diff(signData) == -2);
        UZC = find(diff(signData) == 2);
        
        % check for ZCs
        if isempty(DZC) || isempty(UZC)
            fprintf(1, 'Warning: No zero-crossing found within range\n');
            return;
        end
        
        % Check for earlier initial UZC than DZC
        if DZC(1) > UZC(1)
            UZC(1)=[];
            % in case the last DZC does not have a corresponding UZC then delete it
            if length(DZC) ~= length(UZC)
                DZC(end)=[];
            end
        end
        
        % Check for last DZC with no UZC
        if length(DZC) > length(UZC)
            DZC(end) = [];
        end
        
        % check for ZCs
        if isempty(DZC) || isempty(UZC)
            fprintf(1, 'Warning: No zero-crossing found within range\n');
            return;
        end
        
        % if more than two zero-crossings in range select appropriate one
        [~, DZC_ind] = min(abs(DZC < window - window));
        DZC = DZC(DZC_ind);
        
        UZC = UZC(UZC > DZC);
        [~, UZC_ind] = min(abs(UZC - window));
        UZC = UZC(UZC_ind);
        
        % find minima between ZC
        [neg_amp, neg_id] = min(Data_segment.SWRef(DZC:UZC));
        
        % find positive peak
        pos_amp = max(Data_segment.SWRef(1, neg_id + DZC : end));
        
        % add the parameters to the end of SW structure
        SWid = length(SW) + 1;
        SW(SWid).Ref_Region    = [1];
        SW(SWid).Ref_DownInd   = DZC;
        SW(SWid).Ref_PeakInd   = neg_id + DZC;
        SW(SWid).Ref_UpInd     = UZC;
        SW(SWid).Ref_PeakAmp   = neg_amp;
        SW(SWid).Ref_P2PAmp    = pos_amp - neg_amp;
        SW(SWid).Ref_NegSlope  = min(data_slope(1, DZC : neg_id + DZC));
        SW(SWid).Ref_PosSlope  = max(data_slope(1, neg_id + DZC : UZC));
end

% find the corresponding channels
[~, ~, temp_SW]    = swa_FindSWChannels (Data_segment, Info, SW(SWid), 0);

if isempty(temp_SW)
    fprintf(1, 'Warning: selected wave did not meet channel criteria \n');
    SW(SWid) = [];
    return;
else
   SW(SWid) = temp_SW;
end

% adjust the reference points using the sampling_point and window
SW(SWid).Ref_DownInd = SW(SWid).Ref_DownInd + sample_point - window;
SW(SWid).Ref_PeakInd = SW(SWid).Ref_PeakInd + sample_point - window;
SW(SWid).Ref_UpInd = SW(SWid).Ref_UpInd + sample_point - window;

% find the travelling parameters
[Info, SW] = swa_FindSWTravelling(Info, SW, SWid, 0);

% re-order the SW structure by timing
[~, sortId] = sort([SW.Ref_PeakInd]);
SW = SW(sortId);

new_ind = find(sortId == SWid);

function [SW, new_ind] = add_ST(Data, Info, SW, sample_point, flag_channels)

% define output in case of error
new_ind = [];

% quick check to make sure wave wasn't already found
time_tolerance = 0.150;
if min(abs([SW.Ref_PeakInd] - sample_point)) ...
        < time_tolerance * Info.Recording.sRate
    fprintf(1, 'Warning: Wave already found close to the selected point \n');
    return;
end

% define window of interest
window = round(0.25 * Info.Recording.sRate);

% determine the likely best reference to use
sample_range = sample_point - window : sample_point + window;
[MNP_min, MNP_ind] = min(Data.CWT{1}(:, sample_range)');

% ref wave is strongest negative peak normalised by distance from click
[~, ref_wave] = min(MNP_min./ abs(MNP_ind - window));

% extract a smaller segment of data
Data_segment.STRef = Data.STRef(ref_wave, sample_point - window : sample_point + window);
Data_segment.CWT = Data.CWT{1}(ref_wave, sample_point - window : sample_point + window);

% calculate the slope of the data
data_slope  = [0, diff(Data_segment.CWT, 1, 2)];

% adjust to the nearest MNP
MNP  = find(diff(sign(data_slope)) == 2);
[~, min_ind] = min(abs(MNP - window));

% new sample point adjusted
sample_point = sample_point - window + MNP(min_ind);
sample_range = sample_point - window : sample_point + window;

% get all the data based on new sample point
Data_segment.Raw = Data.Raw(:, sample_range);
Data_segment.STRef = Data.STRef(2, sample_range);
Data_segment.CWT = cellfun(@(x) x(2, sample_range),...
    Data.CWT, 'UniformOutput', false);

% calculate the slope of the data
slopeData = [0 diff(Data_segment.STRef(1, :))];
slopeCWT  = [0 diff(Data_segment.CWT{1}(1, :))];

refMNP = find(diff(sign(slopeData)) == 2); 
refMPP = find(diff(sign(slopeData)) == -2);
MNP = find(diff(sign(slopeCWT)) == 2); 
all_MPP = find(diff(sign(slopeCWT)) == -2);

% find MNP closest to click point
if length(MNP) > 1
    [a, b] = min(abs(MNP - window));
    MNP = MNP(b);
end

% find the nearest MPP around the MNP
MPP = nan(1, 2);
if isempty(max(all_MPP(all_MPP < MNP) - window) + window)
    MPP(1) = 1;
else
    MPP(1) = max(all_MPP(all_MPP < MNP) - window) + window;
end
if isempty(max(all_MPP(all_MPP > MNP) - window) + window)
    MPP(2) = window * 2;
else
    MPP(2) = max(all_MPP(all_MPP > MNP) - window) + window;
end

% check the MPPs
if isempty(MPP)
    MPP(1) = 1;
    MPP(2) = window * 2 + 1;
elseif length(MPP) == 1
    if MPP < MNP
        MPP(2) = window * 2 + 1;
    elseif MPP > MNP
        MPP(2) = MPP(1);
        MPP(1) = 1;
    end
elseif length(MPP) > 2
    % find closest before MNP
    [a, b] = max(MPP(MPP < MNP) - MNP);
    MPP(1) = MPP(b);
    % find closest after MNP
    [a, b] = min(MPP(MPP > MNP) - MNP);
    MPP(2) = MNP + a;
    MPP(3 : end) = [];
end

% peak to peak amp
MPP2MNP = Data_segment.CWT{1}(1, MPP(1)) - Data_segment.CWT{1}(1, MNP(1));
MNP2MPP = Data_segment.CWT{1}(1, MPP(2)) - Data_segment.CWT{1}(1, MNP(1));

% theta_alpha ratio
AlphaAmp = max(Data_segment.CWT{2}(1, MPP(1) : MPP(2)))...
    - min(Data.CWT{2}(1, MPP(1) : MPP(2)));
ThetaAlpha = max(MPP2MNP, MNP2MPP) / AlphaAmp;

[~, Ref_StartId] = max(Data_segment.STRef(1, MPP(1) : MNP(1)));
[~, Ref_NegPeakId] = min(Data_segment.STRef(1, MPP(1) : MPP(2)));
[~, Ref_PosPeakId] = max(Data_segment.STRef(1, MNP(1) : end));

% find notches over minimal amplitude criterion
nPeaks = refMNP(refMNP > MPP(1) & refMNP < MPP(2));
pPeaks = refMPP(refMPP > MPP(1) & refMPP < MPP(2));

% check for some negative peak in the data window
if isempty(nPeaks)
    fprintf(1, 'warning: no negative peaks found in data segment \n');
    return
end

if nPeaks(1) < pPeaks(1)
    pPeaks = [MPP(1) pPeaks];
end
if nPeaks(end) > pPeaks(end)
    pPeaks = [pPeaks MPP(2)];
end

notches = [];
for n = 1 : length(nPeaks);
    
    if Data_segment.STRef(1, pPeaks(n)) ...
            - Data_segment.STRef(1, nPeaks(n)) < 10 ...
        || Data_segment.STRef(1, pPeaks(n + 1)) ...
            - Data_segment.STRef(1, nPeaks(n)) < 10
        continue;
    end
    
    notches(end + 1) = nPeaks(n);
end

% check if SW is empty
if isempty(SW(1).CWT_Start)
    SWid = 1;
else
    SWid = length(SW) + 1;
end

% save all the variables
SW(SWid).Ref_Region          = ref_wave;
SW(SWid).Ref_StartInd        = Ref_StartId + MPP(1);
SW(SWid).Ref_PeakInd         = Ref_NegPeakId + MPP(1);
SW(SWid).Ref_EndInd          = Ref_PosPeakId + MNP(1);
SW(SWid).Ref_NegativeSlope   = mean(slopeData(MPP(1) : (Ref_NegPeakId + MPP(1))));
SW(SWid).Ref_PositiveSlope   = mean(slopeData((Ref_NegPeakId + MPP(1)) : MPP(2)));
SW(SWid).Ref_NotchAmp        = Data_segment.STRef(1, notches);

SW(SWid).CWT_Start           = MPP(1);
SW(SWid).CWT_NegativePeak    = MNP(1);
SW(SWid).CWT_End             = MPP(2);
SW(SWid).CWT_PeakToPeak      = MNP2MPP;
SW(SWid).CWT_ThetaAlpha      = ThetaAlpha;

% find the corresponding channels
if ~flag_channels
    % adjust the reference points using the sampling_point and window
    SW(SWid).Ref_StartInd = SW(SWid).Ref_StartInd + sample_point - window;
    SW(SWid).Ref_PeakInd = SW(SWid).Ref_PeakInd + sample_point - window;
    SW(SWid).Ref_EndInd = SW(SWid).Ref_EndInd + sample_point - window;
    
    SW(SWid).CWT_Start = SW(SWid).CWT_Start + sample_point - window;
    SW(SWid).CWT_End = SW(SWid).CWT_End + sample_point - window;
    SW(SWid).CWT_NegativePeak = SW(SWid).CWT_NegativePeak + sample_point - window;
    
    return
end

[~, ~, temp_SW]    = swa_FindSTChannels (Data_segment, Info, SW(SWid), 0);

if isempty(temp_SW)
    fprintf(1, 'Warning: selected wave did not meet channel criteria \n');
    SW(SWid) = [];
    return;
else
   SW(SWid) = temp_SW;
end

% adjust the reference points using the sampling_point and window
SW(SWid).Ref_StartInd = SW(SWid).Ref_StartInd + sample_point - window;
SW(SWid).Ref_PeakInd = SW(SWid).Ref_PeakInd + sample_point - window;
SW(SWid).Ref_EndInd = SW(SWid).Ref_EndInd + sample_point - window;

SW(SWid).CWT_Start = SW(SWid).CWT_Start + sample_point - window;
SW(SWid).CWT_End = SW(SWid).CWT_End + sample_point - window;
SW(SWid).CWT_NegativePeak = SW(SWid).CWT_NegativePeak + sample_point - window;


% travelling parameters...
% find the traveling parameters
[Info, SW] = swa_FindSTTravelling(Info, SW, SWid);


% -- Burst Calculation -- %
% re-order the SW structure by timing
[~, sortId] = sort([SW.Ref_PeakInd]);
SW = SW(sortId);

new_ind = find(sortId == SWid);

% recalculate the burst
[SW(:).Burst_BurstId] = deal(nan);
[SW(:).Burst_NumberOfWaves] = deal(nan);
[SW(:).Burst_Density] = deal(nan);
    
% pre-allocate counting variables
flag_ST = true(length(SW), 1);
BurstId = 0;

% loop through each wave
for n = 1:length(SW)-1 
      
    % see if the next wave is close to the current one
    if flag_ST(n) && SW(n+1).Ref_PeakInd-SW(n).Ref_PeakInd < ...
            Info.Recording.sRate*Info.Parameters.Burst_Length
    
        % start the count
        burstCount = 1;
        growing = n;
        
        % check the next waves until it isn't close anymore
        for j = n:length(SW)-1
                                  
            if SW(j+1).Ref_PeakInd-SW(j).Ref_PeakInd < Info.Recording.sRate*Info.Parameters.Burst_Length
                
                % add the wave indices to the burst indices
                growing(end + 1) = j + 1;
                burstCount = burstCount + 1;
                flag_ST(j+1) = false;
                
            else
                
                % break the loop if the next wave is not in the burst
                BurstId = BurstId+1;
                break;
                
            end
            
        end
        
    % add the burst information to all the ST waves involved
    [SW(growing).Burst_BurstId] = deal(BurstId);
    [SW(growing).Burst_NumberOfWaves] = deal(burstCount);
    [SW(growing).Burst_Density] = deal((burstCount/(SW(j+1).Ref_PeakInd-SW(n).Ref_PeakInd))*Info.Recording.sRate);
    
    end
end