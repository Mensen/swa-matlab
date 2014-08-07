function [output, h] = swa_wave_summary(SW, Info, type, makePlot)
% type options
%   globality
%   ampVtime
%   wavelengths
%   anglemap
%   topo_density
%   topo_origins

% create the figure if makePlot option is set
if makePlot
    h.fig = figure('color', 'w');
    h.ax  = axes('parent', h.fig);
end

% switch between summary types
switch type
case 'globality'
    output = sum([SW.Channels_Active])/length(SW(1).Channels_Active)*100;
    if makePlot
        hist(h.ax, output);
        set(h.ax,...
            'title', text('string', 'Waves Globality'),...
            'XLim', [0, 100]);

        set(get(h.ax, 'xlabel'), 'string', 'Percentage of channels in the wave');
        set(get(h.ax, 'ylabel'), 'string', 'Number of Waves');
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
        set(h.ax,...
            'title', text('string', 'Travel Distance'));

        set(get(h.ax, 'xlabel'), 'string', 'Distance Travelled');
        set(get(h.ax, 'ylabel'), 'string', 'Number of Waves');
    end

case 'ampVtime'
    output(1,:)=[SW.Ref_PeakAmp];
    output(2,:)=[SW.Ref_PeakInd];
    if makePlot
        h.plt = scatter(output(2,:), output(1,:));
        set(h.plt,...
            'marker',           'v'     ,...
            'markerFaceColor',  'k'     ,...
            'markerEdgeColor',  'r')

        set(h.ax,...
            'title', text('string', 'Amplitude over Time'));

        set(get(h.ax, 'xlabel'), 'string', 'Time (samples)');
        set(get(h.ax, 'ylabel'), 'string', 'Reference Amplitude');
    end

case 'wavelengths'
    output = ([SW.Ref_UpInd]-[SW.Ref_DownInd])/Info.Recording.sRate*1000;
    if makePlot
        hist(h.ax, output);
        set(h.ax,...
            'title', text('string', 'Wavelengths'),...
            'XLim', [0, 1500]);

        set(get(h.ax, 'xlabel'), 'string', 'Wavelengths (ms)');
        set(get(h.ax, 'ylabel'), 'string', 'Number of Waves');
    end

case 'anglemap'
    count = 0;
    for n = 1:length(SW)
        if iscell(SW(n).Travelling_Streams)
            count = count+1;
            streams{count} = SW(n).Travelling_Streams{1};
        end
    end
    output = cellfun(@(x) atan2d(x(1,end)- x(1,1),x(2,end)-x(2,1)), streams);

    if makePlot
        h.plt = rose(h.ax, output*(pi/180));
        xc    = get(h.plt, 'Xdata');
        yc    = get(h.plt, 'Ydata');

        set(h.ax,...
            'title', text('string', 'Angle Map (Longest Stream)'));
        % create a patch object to shade the rose diagram
        h.ptch = patch(xc, yc, 'b');
        set(h.ptch, 'edgeColor', 'w', 'linewidth', 2);
    end

case 'topo_density'
    output  = zeros(Info.Recording.dataDim(1),1);
    for n = 1:length(SW)
        output(SW(n).Channels_Active)       = output(SW(n).Channels_Active) +1;
    end

    h.plt = swa_Topoplot(...
        [], Info.Electrodes,...
        'Data',             output                ,...
        'GS',               Info.Parameters.Stream_GS,...
        'Axes',             h.ax                  ,...
        'NumContours',      10                     ,...
        'PlotSurface',      0                     );

    colormap(flipud(hot));

case 'topo_origins'
    output  = zeros(Info.Recording.dataDim(1),1);
    for n = 1:length(SW)
        output(SW(n).Travelling_Delays<1)  = output(SW(n).Travelling_Delays<1) + 1;
    end

    h.plt = swa_Topoplot(...
        [], Info.Electrodes,...
        'Data',             output                ,...
        'GS',               Info.Parameters.Stream_GS,...
        'Axes',             h.ax                  ,...
        'NumContours',      10                     ,...
        'PlotSurface',      0                     );

    colormap(flipud(hot));

%TODO: correlation between MPP->MNP || MNP->MPP
%TODO: average delay map
otherwise
    fprintf(1, 'Error: %s is not a valid summary type', type);
    return;
end
