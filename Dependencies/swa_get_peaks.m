function [MNP, MPP] = swa_get_peaks(slope_data, Info, flag_notch)
% find the positive and negative peaks within a channel

if nargin < 3
    flag_notch = false;
end

% find all the negative peaks
% when slope goes from negative to a positive
MNP  = find(diff(sign(slope_data)) == 2);
% Find all the positive peaks
MPP  = find(diff(sign(slope_data)) == -2);

% Check for earlier MPP than MNP
if MNP(1) < MPP(1)
    MNP(1) = [];
end
% Check that last MNP has a later MPP
if MNP(end) > MPP(end)
    MNP(end)=[];
end

% iteratively erase small notches
if flag_notch
    nb = 1;
    while nb > 0;
        posBumps = MPP(2 : end) - MNP < ...
            Info.Parameters.Ref_WaveLength(1) * Info.Recording.sRate / 10;
        MPP([false, posBumps]) = [];
        MNP(posBumps) = [];
        
        negBumps = MNP - MPP(1 : end - 1) < ...
            Info.Parameters.Ref_WaveLength(1) * Info.Recording.sRate / 10;
        MPP(negBumps) = [];
        MNP(negBumps) = [];
        
        nb = max(sum(posBumps), sum(negBumps));
    end
end
           