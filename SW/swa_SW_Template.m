%% -- Workflow and Plots for Slow Wave Analysis -- %%

% read the preprocessed data or another swa file

% for eeglab files
[Data, Info] = swa_convertFromEEGLAB();
% or if you have previously analysed some data
[Data, Info, SW] = swa_load_previous();

%% Template for envelope + filter analysis %%

Info = swa_getInfoDefaults(Info, 'SW', 'envelope');

[Data.SWRef, Info]  = swa_CalculateReference (Data.Raw, Info);
[Data, Info, SW]    = swa_FindSWRef (Data, Info);
[Data, Info, SW]    = swa_FindSWChannels (Data, Info, SW);
[Info, SW]          = swa_FindSWTravelling (Info, SW);

% Replace the data with a file pointer if drive space is a concern
Data.Raw = Info.Recording.dataFile;

% Save the filtered to a simple binary file (like .fdt)
filteredName = [Info.Recording.dataFile(1:end-4), '_filtered.fdt'];
if ~exist(filteredName, 'file')
    swa_save_data(Data.Filtered, filteredName);
end
Data.Filtered = filteredName;

% Done! Use the swa_Explorer to visualise the results.
[saveFile, savePath] = uiputfile('*.mat');
save([savePath, saveFile], 'Data', 'Info', 'SW', '-mat');



%% -- Template for Regions Reference -- %%
% set mdc specific defaults
Info = swa_getInfoDefaults(Info, 'SW', 'MDC');

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