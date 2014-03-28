%% -- Workflow and Plots for Slow Wave Analysis -- %%

%% Initial Parameter Settings

Info.Parameters.Filter_Apply    = true;
Info.Parameters.Filter_Method   = 'Chebyshev';      % 'Chebyshev'/'Buttersworth'
Info.Parameters.Filter_hPass    = 0.2;
Info.Parameters.Filter_lPass    = 4;
Info.Parameters.Filter_order    = 2;

Info.Parameters.Ref_Method      = 'Envelope';
Info.Parameters.Ref_UseInside   = 1;
Info.Parameters.Ref_NegAmpMin   = 80;
Info.Parameters.Ref_ZCLength    = [0.25 1.25];
Info.Parameters.Ref_SlopeMin    = 0.90;
Info.Parameters.Ref_Peak2Peak   = 140;              % Only for MDC

Info.Parameters.Channels_CorrThresh = 0.9;
Info.Parameters.Channels_WinSize    = 0.2;

Info.Parameters.Stream_GS       = 40; % size of interpolation grid
Info.Parameters.Stream_MinDelay = 40; % minimum travel time (ms)

%% -- Scripts to run -- %%
[Data.Ref, Info]    = swa_CalculateReference(Data.SWS, Info);

[SW, Info]          = swa_FindSWRef(Data.Ref, Info);

[SW, Data, Info]    = swa_FindSWChannels(SW, Data, Info);

[SW,Info]           = swa_FindSWStreams(SW,Info);



%% -- Scripts for Four Regions
Info.Method = 'MDC';

[Data.Ref, Info]    = swa_CalculateReference(Data.SWS, Info);

% Independently for each slow wave
[SW, Info]          = swa_FindSWRef(Data.Ref(1,:), Info);
[SW, Info]          = swa_FindSWRef(Data.Ref(2,:), Info, SW);
[SW, Info]          = swa_FindSWRef(Data.Ref(3,:), Info, SW);
[SW, Info]          = swa_FindSWRef(Data.Ref(4,:), Info, SW);

% Sort SW in case it found additional channels put at the end
AllPeaks = [SW.Ref_PeakId];
[~,sortId] = sort(AllPeaks);
SW = SW(sortId);
clear sortId AllPeaks

[SW, Data, Info]    = swa_FindSWChannels(SW, Data, Info);

[SW,Info]           = swa_FindSWStreams(SW,Info);
%% Plotting Functions %%
nSW = 4;
win = round(0.4*Info.sRate);

% All the data...
figure('Color', 'w');
plot(Data.SWS','Color', [0.5 0.5 0.5], 'linewidth', 0.5) % all channels in grey
hold on;
plot(Data.SWS(25,:)','Color', 'k', 'linewidth', 3) %channel 25 in black
plot(Data.SWS(SW(nSW).channels,:)','Color', 'k', 'linewidth', 2) % all channels in grey
plot(Data.Ref','b', 'linewidth', 3) % reference in blue

% Individual Wave...
figure('Color', 'w');
plot(Data.SWS(:,SW(nSW).negmax-win:SW(nSW).negmax+win)','Color', [0.5 0.5 0.5], 'linewidth', 0.5); 
hold on;
plot(Data.SWS(SW(nSW).channels,SW(nSW).negmax-win:SW(nSW).negmax+win)','Color', 'k', 'linewidth', 2); 
% plot(Data.Filtered(:,EW(nEW).negmax-win:EW(nEW).negmax+win)','k');
plot(Data.Ref(:,SW(nSW).negmax-win:SW(nSW).negmax+win),'r','linewidth',3);

% Plot Delay Topoplot
nSW = 1;

H = ept_Topoplot(SW(nSW).Delays,Info.Electrodes, 'PlotSurface', 1, 'PlotContour',0);
% H = ept_Topoplot(DelData,Info.Electrodes, 'NumContours', 10, 'PlotContour',1);
colormap(flipud(hot));
%Mark origin
set(H.Channels(SW(nSW).Channels(1)) ,...
    'Color',            'k'         ,...
    'String',           'o'         ,...
    'FontSize',         20          );