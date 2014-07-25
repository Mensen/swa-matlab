%% -- Workflow and Plots for Slow Wave Analysis -- %%

% read the preprocessed data or another swa file

% for eeglab files
[Data, Info] = swa_convertFromEEGLAB();

%% Initial Parameter Settings

Info.Parameters.Filter_Apply    = true;
Info.Parameters.Filter_Method   = 'Chebyshev';      % 'Chebyshev'/'Buttersworth'
Info.Parameters.Filter_hPass    = 0.2;
Info.Parameters.Filter_lPass    = 4;
Info.Parameters.Filter_order    = 2;

Info.Parameters.Ref_Method      = 'Envelope';
Info.Parameters.Ref_UseInside   = 1;
Info.Parameters.Ref_AmpStd      = 6;                % Standard deviations from mean negativity
Info.Parameters.Ref_NegAmpMin   = 80;               % Only used if Ref_AmpStd not set
Info.Parameters.Ref_ZCLength    = [0.25 1.25];      % Length criteria between zero crossings
Info.Parameters.Ref_SlopeMin    = 0.90;             % Percentage cut-off for slopes
Info.Parameters.Ref_Peak2Peak   = 140;              % Only for MDC

Info.Parameters.Channels_CorrThresh = 0.9;
Info.Parameters.Channels_WinSize    = 0.2;

Info.Parameters.Stream_GS       = 40; % size of interpolation grid
Info.Parameters.Stream_MinDelay = 40; % minimum travel time (ms)

%% -- Scripts to run -- %%
[Data.Ref, Info]    = swa_CalculateReference(Data.Raw, Info);

[SW, Info]          = swa_FindSWRef(Data.Ref, Info);

[SW, Data, Info]    = swa_FindSWChannels(SW, Data, Info);

[SW, Info]          = swa_FindSWTravelling(SW, Info);

% Replace the data with a file pointer if drive space is a concern
Data.Raw = Info.Recording.dataFile;

% Remove filtered dataset
Data.Filtered = [];
% Or at least make it single precision
Data.Filtered = single(Data.Filtered);

% Done! Use the swa_Explorer to visualise the results.
[saveFile, savePath] = uiputfile('*.mat');
save([savePath, saveFile], 'Data', 'Info', 'SW', '-mat');


%% -- Template for Four Regions Reference -- %%
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

[SW,Info]           = swa_FindSWTravelling(SW,Info);


%% Plotting Functions %%
nSW = 4;
win = round(0.4*Info.sRate);

% All the data...
figure('Color', 'w');
plot(Data.Raw','Color', [0.5 0.5 0.5], 'linewidth', 0.5) % all channels in grey
hold on;
plot(Data.Raw(25,:)','Color', 'k', 'linewidth', 3) %channel 25 in black
plot(Data.Raw(SW(nSW).channels,:)','Color', 'k', 'linewidth', 2) % all channels in grey
plot(Data.Ref','b', 'linewidth', 3) % reference in blue

% Individual Wave...
figure('Color', 'w');
plot(Data.Raw(:,SW(nSW).negmax-win:SW(nSW).negmax+win)','Color', [0.5 0.5 0.5], 'linewidth', 0.5); 
hold on;
plot(Data.Raw(SW(nSW).channels,SW(nSW).negmax-win:SW(nSW).negmax+win)','Color', 'k', 'linewidth', 2); 
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