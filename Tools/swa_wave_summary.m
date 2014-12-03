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
            'ampVtime'      ;...
            'wavelengths'   ;...
            'anglemap'      ;...
            'topo_density'  ;...
            'topo_origins'  };
        return;
    else
        fprintf(1, 'Warning: Use ''return options'' as input to see current plotting options');
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
            hist(h.ax, output);
            if isempty(axes_handle)
                % set the title and labels
                set(h.ax,...
                    'title', text('string', 'Waves Globality'),...
                    'XLim', [0, 100]);
                
                set(get(h.ax, 'xlabel'), 'string', 'Percentage of channels in the wave');
                set(get(h.ax, 'ylabel'), 'string', 'Number of Waves');
            end
        end
        
    case 'distances'
        count = 0;
        for n = 1:length(SW)
            if iscell(SW(n).Travelling_Streams)
                count = count+1;
                streams{count} = SW(n).Travelling_Streams{1};
            end
        end
        output = cellfun(@(x) (sum((x(:,1)-x(:,end)).^2))^0.5, streams); % total displacement
        
        if makePlot
            hist(h.ax, output);
            if isempty(axes_handle)
                set(h.ax,...
                    'title', text('string', 'Travel Distance'));
                
                set(get(h.ax, 'xlabel'), 'string', 'Distance Travelled');
                set(get(h.ax, 'ylabel'), 'string', 'Number of Waves');
            end
        end
        
    case 'ampVtime'
        output(1,:)=[SW.Ref_PeakAmp];
        output(2,:)=[SW.Ref_PeakInd];
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
        
    case 'wavelengths'
        output = ([SW.Ref_UpInd]-[SW.Ref_DownInd])/Info.Recording.sRate*1000;
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

            % create a patch object to shade the rose diagram
            h.ptch = patch(xc, yc, 'b', 'parent', h.ax);
            set(h.ptch, 'edgeColor', 'w', 'linewidth', 2);
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
        
        %TODO: correlation between MPP->MNP || MNP->MPP
        %TODO: average delay map
    otherwise
        fprintf(1, 'Error: %s is not a valid summary type', type);
        return;
end
