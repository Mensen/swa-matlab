function [SW, new_ind] = swa_manual_addition(Data, Info, SW, sample_point)
% wave parameters are calculated from manually selected sample point


% extract a smaller segment of data
window = round(0.75 * Info.Recording.sRate);

Data_segment.Raw = Data.Raw(:, sample_point - window :sample_point + window);
Data_segment.SWRef = Data.SWRef(1, sample_point - window :sample_point + window);

% quick check to make sure wave wasn't already found
time_tolerance = 0.750;
if min(abs([SW.Ref_PeakInd] - sample_point)) ...
        < time_tolerance * Info.Recording.sRate
    fprintf(1, 'Warning: Wave already found close to the selected point \n');
    new_ind = [];
    return;
end

% calculate the slope of the data
data_slope  = [0 diff(Data_segment.SWRef)];

switch lower(Info.Parameters.Ref_InspectionPoint)
    
    case 'mnp'
        % get the local minima and maxima (and eliminate small notches)
        [MNP, MPP] = swa_get_peaks(data_slope, Info, 1);

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
        
        % Check for earlier initial UZC than DZC
        if DZC(1)>UZC(1)
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
[~, ~, SW(SWid)]    = swa_FindSWChannels (Data_segment, Info, SW(SWid), 0);

% adjust the reference points using the sampling_point and window
SW(SWid).Ref_DownInd = SW(SWid).Ref_DownInd + sample_point - window;
SW(SWid).Ref_PeakInd = SW(SWid).Ref_PeakInd + sample_point - window;
SW(SWid).Ref_UpInd = SW(SWid).Ref_UpInd + sample_point - window;

% find the travelling parameters
[Info, SW] = swa_FindSWTravelling(Info, SW, SWid, 0);

% re-order the SW structure by timing
[~, sortId] = sort([SW.Ref_PeakInd]);
SW = SW(sortId);

new_ind = find([SW.Ref_PeakInd] == MNP + sample_point- window);
