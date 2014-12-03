function [Data, Info, ST] = swa_FindSTChannels(Data, Info, ST)

fprintf(1, 'Analysis: Finding Saw-Tooth Waves in Individual Channels... \n');
%% -- Calculate CWT Waves -- %%

FreqRange   = Info.Parameters.CWT_hPass:Info.Parameters.CWT_lPass;
Scale_theta = (centfrq('morl')./FreqRange) * Info.Recording.sRate;

Channels_Theta = zeros(size(Data.Raw));
WaitHandle = waitbar(0,'Please wait...', 'Name', 'Calculating Wavelets');
for i = 1:size(Data.Raw,1)
    waitbar(i/size(Data.Raw,1),WaitHandle,sprintf('Channel %d of %d',i, size(Data.Raw,1)))
    Channels_Theta(i,:) = mean(cwt(Data.Raw(i,:),Scale_theta,'morl'));
end
delete(WaitHandle);

%% -- Find corresponding channels from the reference wave -- %%
Window = round(Info.Parameters.Channels_WinSize*Info.Recording.sRate);
for nST = 1:length(ST)

    range = (ST(nST).CWT_NegativePeak-Window):(ST(nST).CWT_NegativePeak+Window);
    
    % Negative Theta Amplitude Criteria
    [Ch_Min, Ch_Id] = min(Channels_Theta(:,range), [],2);
    ST(nST).Channels_Active = false(size(Channels_Theta,1),1);
    ST(nST).Channels_Active(Ch_Min < -Info.Parameters.CWT_AmpThresh(ST(nST).Ref_Region(1))/2) = true;
    
    % Eliminate channels with delay of 1 since they are most likely just
    % the minimum on a positive slope of a previous wave...
    ST(nST).Channels_Active(Ch_Id == 1) = false;
        
    % Calculate Parameters
    ST(nST).Channels_Globality      = sum(ST(nST).Channels_Active)/size(Channels_Theta,1)*100;
    
    ST(nST).Channels_Peak2PeakAmp   = nan(size(Channels_Theta,1),1);
    ST(nST).Channels_Peak2PeakAmp(ST(nST).Channels_Active) = max(Data.Raw(ST(nST).Channels_Active, ST(nST).CWT_End-Window:ST(nST).CWT_End+Window),[],2)-min(Data.Raw(ST(nST).Channels_Active, range),[],2);
        
	ST(nST).Channels_NegativeMax    = min(min(Data.Raw(ST(nST).Channels_Active, range)));
	ST(nST).Channels_PositiveMax    = max(max(Data.Raw(ST(nST).Channels_Active, ST(nST).CWT_End-Window:ST(nST).CWT_End+Window)));
        
    ST(nST).Travelling_Delays = nan(size(Channels_Theta,1),1);
    ST(nST).Travelling_Delays(ST(nST).Channels_Active) = Ch_Id(ST(nST).Channels_Active)-min(Ch_Id(ST(nST).Channels_Active));
        
end
fprintf(1, 'Done. \n');

