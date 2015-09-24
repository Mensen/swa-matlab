function [output, h] = swa_wave_summary(SW, Info, type, makePlot, axes_handle)
% function to output and plot a summary statistic for swa output files

% set default plot parameters
if nargin < 4
    makePlot = 0;
    axes_handle = [];
elseif nargin < 5
    axes_handle = [];
end

% if function is called with a single 'return options' argument then return
% the list of current available summary options
if isa(SW, 'char')
    if strcmp(SW, 'return options')
        output = {...
            'globality'     ;...
            'distances'     ;...
            'amplitudes'    ;...
            'ampVtime'      ;...
            'ampVglobality' ;...
            'wavelengths'   ;...
            'anglemap'      ;...
            'topo_density'  ;...
            'topo_origins'  ;...
            'topo_streams'  ;...
            'topo_meandelay';...
            'topo_streamorigins'};
        return;
    else
        fprintf(1, 'Error: Use ''return options'' as input to see current plotting options');
        return;
    end
end


% create the figure if makePlot option is set
if makePlot
    if isempty(axes_handle)
        h.fig = figure('color', 'w');
        h.ax  = axes('parent', h.fig);
    else
        h.ax  = axes_handle;
    end
end

% switch between summary types
switch type
    
    case 'globality'
        output = sum([SW.Channels_Active])/length(SW(1).Channels_Active)*100;
        if makePlot
            [counts, centers] = hist(output);
            bar(centers, counts,...
                'parent', h.ax, ...
                'barWidth', 1);
            % set axis limits always
            set(h.ax,...
                'xlim', [0, 100], ...
                'ylim', [0, max(counts)]);
            if isempty(axes_handle)
                % set the title and labels for new figures
                set(h.ax,...
                    'title', text('string', 'Waves Globality'));               
                set(get(h.ax, 'xlabel'), 'string', 'Percentage of channels in the wave');
                set(get(h.ax, 'ylabel'), 'string', 'Number of Waves');
            end
        end
        
    case 'distances'
        % histogram of displacement distribution
        
        count = 0;
        streams = cell(1);
        for n = 1:length(SW)
            if iscell(SW(n).Travelling_Streams)
                count = count+1;
                streams{count} = SW(n).Travelling_Streams{1};
            end
        end
        
        % check if any streams were found
        if isempty(streams{1})
            fprintf('Warning: no streams were found for calculation\n');
            return
        end
        
        % get the total displacement of each stream
        output = cellfun(@(x) (sum((x(:,1)-x(:,end)).^2))^0.5, streams);
        
        if makePlot
            hist(h.ax, output);
            if isempty(axes_handle)
                set(h.ax,...
                    'title', text('string', 'Travel Distance'));
                
                set(get(h.ax, 'xlabel'), 'string', 'Distance Travelled');
                set(get(h.ax, 'ylabel'), 'string', 'Number of Waves');
            end
        end
    
    case 'amplitudes'
        % for SW and ST
        if isfield(SW, 'Channels_NegAmp')
            output = min([SW.Channels_NegAmp]);
        else
            output = max([SW.Channels_Peak2PeakAmp]);
        end
        
        if makePlot
            hist(h.ax, output);
            if isempty(axes_handle)
                % set the title and labels
                set(h.ax,...
                    'title', text('string', 'Peak Channel Amplitude'));
                
                set(get(h.ax, 'xlabel'), 'string', 'Wave Amplitude');
                set(get(h.ax, 'ylabel'), 'string', 'Number of Waves');
            end
        end
        
    case 'ampVtime'
        % for SW and ST
        if isfield(SW, 'Ref_PeakAmp')
            output(1, :)= [SW.Ref_PeakAmp];
            output(2, :)= [SW.Ref_PeakInd];
        else
            output(1, :)= [SW.Ref_Peak2Peak];
            output(2, :)= [SW.Ref_Start];
        end
        
        if makePlot
            h.plt = scatter(output(2,:), output(1,:), 'parent', h.ax);
            set(h.plt,...
                'marker',           'v'     ,...
                'markerFaceColor',  'k'     ,...
                'markerEdgeColor',  'r')
            
            % set the x-axis limits to the maximum of the data
            set(h.ax,...
                'xlim', [0, max(output(2,:))]);
            
            if isempty(axes_handle)
                % set the title and labels
                set(h.ax,...
                    'title', text('string', 'Amplitude over Time'));
                
                set(get(h.ax, 'xlabel'), 'string', 'Time (samples)');
                set(get(h.ax, 'ylabel'), 'string', 'Reference Amplitude');
            end
        end
        
    case 'ampVglobality'
        % for SW and ST
        if isfield(SW, 'Ref_PeakAmp')
            output(1, :)= [SW.Ref_PeakAmp];
            output(2, :)= sum([SW.Channels_Active])/length(SW(1).Channels_Active)*100;
        else
            output(1, :)= [SW.Ref_Peak2Peak];
            output(2, :)= sum([SW.Channels_Active])/length(SW(1).Channels_Active)*100;
        end

        if makePlot
            h.plt = scatter(output(2,:), output(1,:), 'parent', h.ax);
            set(h.plt,...
                'marker',           'v'     ,...
                'markerFaceColor',  'k'     ,...
                'markerEdgeColor',  'r')
            
            % set the x-axis limits to the maximum of the data
            set(h.ax,...
                'xlim', [0, max(output(2,:))]);
            
            if isempty(axes_handle)
                % set the title and labels
                set(h.ax,...
                    'title', text('string', 'Amplitude over Time'));
                
                set(get(h.ax, 'xlabel'), 'string', 'Globality(%)');
                set(get(h.ax, 'ylabel'), 'string', 'Reference Amplitude');
            end
        end    
        
    case 'wavelengths'
        % for SW and ST
        if isfield(SW, 'Ref_UpInd')
            output = ([SW.Ref_UpInd] - [SW.Ref_DownInd]) ...
                /Info.Recording.sRate * 1000;
        else
            output = ([SW.Ref_Start] - [SW.Ref_End]) ...
                / Info.Recording.sRate * 1000;
        end
        
        if makePlot
            hist(h.ax, output);
            if isempty(axes_handle)
                % set the title and labels
                set(h.ax,...
                    'title', text('string', 'Wavelengths'),...
                    'XLim', [0, 1500]);

                set(get(h.ax, 'xlabel'), 'string', 'Wavelengths (ms)');
                set(get(h.ax, 'ylabel'), 'string', 'Number of Waves');
            end
        end

    case 'anglemap'
        count = 0;
        for n = 1:length(SW)
            if iscell(SW(n).Travelling_Streams)
                count = count+1;
                streams{count} = SW(n).Travelling_Streams{1};
            end
        end

        % check for any streams present
        if exist('streams', 'var')
            output = cellfun(@(x) atan2d(x(1,end)- x(1,1),x(2,end)-x(2,1)), streams);
        else
            output = [];
        end

        if makePlot
            h.plt = rose(h.ax, output*(pi/180));
            xc    = get(h.plt, 'Xdata');
            yc    = get(h.plt, 'Ydata');

            if isempty(axes_handle)
                % set the title and labels
                set(h.ax,...
                    'title', text('string', 'Angle Map (Longest Stream)'));
            end

            % TODO: Fix patches on rose diagram after 2014b
            % create a patch object to shade the rose diagram
%             h.ptch = patch(xc, yc, 'b', 'parent', h.ax);
%             set(h.ptch, 'edgeColor', 'w', 'linewidth', 2);
        end

    case 'topo_density'
        output  = zeros(Info.Recording.dataDim(1),1);
        for n = 1:length(SW)
            output(SW(n).Channels_Active)       = output(SW(n).Channels_Active) +1;
        end
        
        if makePlot
            h.plt = swa_Topoplot(...
                [], Info.Electrodes,...
                'Data',             output                ,...
                'GS',               Info.Parameters.Travelling_GS,...
                'Axes',             h.ax                  ,...
                'NumContours',      10                     ,...
                'PlotSurface',      0                     );
        end
        
    case 'topo_origins'
        output  = zeros(Info.Recording.dataDim(1),1);
        for n = 1:length(SW)
            output(SW(n).Travelling_Delays<1)  = output(SW(n).Travelling_Delays<1) + 1;
        end
        
        if makePlot
            h.plt = swa_Topoplot(...
                [], Info.Electrodes,...
                'Data',             output                ,...
                'GS',               Info.Parameters.Travelling_GS,...
                'Axes',             h.ax                  ,...
                'NumContours',      10                     ,...
                'PlotSurface',      0                     );
        end
        
    case 'topo_streams'
        % create a topography displaying all the longest steam lines
        
        % find indices of SW that have some streams
        empty_ind = arrayfun(@(x) isempty(x.Travelling_Streams), SW);
        
        % find indices of SW over 50th percentile globality
        long_ind = ~[SW.Channels_Globality] < prctile([SW.Channels_Globality], 50);
        
        % get the longest streams
        all_streams = arrayfun(@(x) x.Travelling_Streams{1},...
            SW(~empty_ind & long_ind), 'uniform', false);
        
        % take only the first 150 if more
        if length(all_streams) > 150
            all_streams = all_streams(1:150);
        end
        
        h = swa_Topoplot...
            (nan(40, 40), Info.Electrodes,...
            'Axes',             axes_handle, ...
            'NumContours',      10, ...
            'PlotContour',      0, ...
            'PlotSurface',      0, ...            
            'PlotChannels',     0, ...
            'PlotStreams',      1, ...
            'Streams',          all_streams,...
            'streamWidth',      150, ...
            'streamColor',      [0.5, 0.5, 0.8]);
        
    case 'topo_meandelay'
        % plots the mean delays (in samples) of all the waves
        output = nanmean(cell2mat(arrayfun(...
            @(x) x.Travelling_Delays, SW,...
            'UniformOutput', false)), 2);
        
        if makePlot
            h.plt = swa_Topoplot(...
                [], Info.Electrodes,...
                'Data',             output                ,...
                'GS',               Info.Parameters.Travelling_GS,...
                'Axes',             h.ax                  ,...
                'NumContours',      10                     ,...
                'PlotSurface',      0                     );
        end
        
    case 'topo_streamorigins'
        % plot the origins of the travelling streams
        
        % remove all SW without streams found
        bad_ind = arrayfun(@(x) isempty(x.Travelling_Streams), SW);
        SW(bad_ind) = [];
        
        % check there still are some streams
        if isempty(SW)
            fprintf('Warning: no streams were found for calculation\n');
            return
        end
        
        output = cell2mat(arrayfun(@(x) x.Travelling_Streams{1}(:, 1), SW,...
            'UniformOutput', false));
        
        if makePlot
            % plot empty head
            h = swa_Topoplot...
                (nan(40, 40), Info.Electrodes,...
                'Axes',             axes_handle, ...
                'PlotContour',      0, ...
                'PlotSurface',      0, ...
                'PlotChannels',     0, ...
                'PlotStreams',      0);
                       
            % plot basic markers
            h.scat = scatter(output(2, :), output(1, :),...
                'sizeData', 100, ...
                'marker', 'v', ...
                'lineWidth', 1, ...
                'markerEdgeColor', [0.2, 0.2, 0.2],...
                'markerFaceColor', [0.8, 0.8, 0.8]);
        end
        
        %TODO: correlation between MPP->MNP || MNP->MPP
        
    otherwise
        fprintf(1, 'Error: %s is not a valid summary type', type);
        return;
end
