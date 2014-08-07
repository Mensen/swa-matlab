%% -- Workflow and Plots for Slow Wave Analysis -- %%

% read the preprocessed data or another swa file

% for eeglab files
[Data, Info] = swa_convertFromEEGLAB();
% or if you have previously analysed some data
[Data, Info, SW] = swa_load_previous();

%% Initial Parameter Settings

% filter parameters
Info.Parameters.Filter_Apply    = [];
Info.Parameters.Filter_Method   = 'Chebyshev';      % 'Chebyshev'/'Buttersworth'
Info.Parameters.Filter_hPass    = 0.2;
Info.Parameters.Filter_lPass    = 4;
Info.Parameters.Filter_order    = 2;

% reference detection
Info.Parameters.Ref_Method      = [];
Info.Parameters.Ref_ZCorMNP     = 'MNP';
Info.Parameters.Ref_UseInside   = 1;                % Use interior head channels or all
Info.Parameters.Ref_AmpStd      = 4.5;              % Standard deviations from mean negativity
Info.Parameters.Ref_NegAmpMin   = 80;               % Only used if Ref_AmpStd not set
Info.Parameters.Ref_WaveLength  = [0.25 1.25];      % Length criteria between zero crossings
Info.Parameters.Ref_SlopeMin    = 0.90;             % Percentage cut-off for slopes
Info.Parameters.Ref_Peak2Peak   = [];               % Only for MDC

% channel detection
Info.Parameters.Channels_CorrThresh = 0.9;
Info.Parameters.Channels_WinSize    = 0.2;

% travelling parameters
Info.Parameters.Stream_GS       = 40; % size of interpolation grid
Info.Parameters.Stream_MinDelay = 40; % minimum travel time (ms)

%% Template for envelope + filter analysis %%

% set envelope specific defaults
Info.Parameters.Ref_Method      = 'Envelope';
Info.Parameters.Filter_Apply    = true;

[Data.SWRef, Info]  = swa_CalculateReference (Data.Raw, Info);

[Data, Info, SW]    = swa_FindSWRef (Data, Info);

[Data, Info, SW]    = swa_FindSWChannels (Data, Info, SW);

[Info, SW]          = swa_FindSWTravelling (Info, SW);


% Replace the data with a file pointer if drive space is a concern
Data.Raw = Info.Recording.dataFile;

% What to do with the filtered dataset?
% `````````````````````````````````````
% Save it to a simple binary file (like fdt)
filteredName = [Info.Recording.dataFile(1:end-4), '_filtered.fdt'];
if ~exist(filteredName, 'file')
    swa_save_data(Data.Filtered, filteredName);
end
Data.Filtered = filteredName;

% Done! Use the swa_Explorer to visualise the results.
[saveFile, savePath] = uiputfile('*.mat');
save([savePath, saveFile], 'Data', 'Info', 'SW', '-mat');

%% -- Template for Regions Reference -- %%
% set envelope specific defaults
Info.Method = 'MDC';
Info.Parameters.Ref_Peak2Peak   = 140;

[Data.SWRef, Info]  = swa_CalculateReference(Data.Raw, Info);

[Data, Info, SW]    = swa_FindSWRef(Data, Info);

[Data, Info, SW]    = swa_FindSWChannels(Data, Info, SW);

[Info, SW]          = swa_FindSWTravelling(Info, SW);


%% Plotting Functions %%

% Plot the reference wave in relation to all waves
figure('color', 'w'); plot(1:5000, Data.Raw(:, 5001:10000), 'k'); hold on; plot(Data.SWRef(1,5001:10000), 'linewidth', 5);

% Select a slow wave
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