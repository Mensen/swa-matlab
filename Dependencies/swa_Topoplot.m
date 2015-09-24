function H = swa_Topoplot(DelayMap, e_loc, varargin)

%% Set defaults
ContourWidth        = 0.2;
NumContours         = 12;

PlotContour         = 1;            % Determines whether the contour lines are drawn
PlotSurface         = 0;            % Determines whether the surface is drawn
PlotHead            = 1;            % Determines whether the head is drawn
PlotChannels        = 1;            % Determines whether the channels are drawn
PlotStreams         = 1;

Streams             = [];
streamWidth         = 50;           % thickness of the streamlines (higher the thinner)
streamColor         = 'w';

HeadWidth           = 2.5;
HeadColor           = [0,0,0];

NewFigure           = 0;            % 0/1 - Whether to explicitly draw a new figure for the topoplot
Axes                = 0;

%% Process Secondary Arguments
if nargin > 2
  if ~(round(nargin/2) == nargin/2)
    error('Odd number of input arguments??')
  end
  for i = 1:2:length(varargin)
    Param = varargin{i};
    Value = varargin{i+1};
    if ~ischar(Param)
      error('Flag arguments must be strings')
    end
    Param = lower(Param);

    switch Param
        case 'headwidth'
            HeadWidth           = Value;
        case 'numcontours'
            NumContours         = Value;
        case 'newfigure'
            NewFigure           = Value;
        case 'axes'
            Axes                = Value;
        case 'plotcontour'
            PlotContour         = Value;
        case 'plotsurface'
            PlotSurface         = Value;
        case 'plotchannels'
            PlotChannels        = Value;
        case 'plothead'
            PlotHead            = Value;
        case 'plotorigins'
            PlotOrigins         = Value;
        case 'plotstreams'
            PlotStreams         = Value;
        case 'f'
            F                   = Value;
        case 'streams'
            Streams             = Value;
        case 'gs'
            GS                  = Value;
        case 'data'
            Data = Value;
        case 'streamwidth'
            streamWidth = Value;
        case 'streamcolor'
            streamColor = Value;
        case 'colorlimits'
            colorlimits         = Value;
        otherwise
            display (['Unknown parameter setting: ' Param])
    end
  end
end

%% Adjust Settings based on Arguments

% Overwrite contours plot if the interpolated surface is drawn
if PlotSurface == 1; PlotContour = 0; end

if ~exist('GS', 'var')
    GS = 40;
%     fprintf(1, 'Warning: Set gridscale as parameter, using default [GS = 40] \n');
elseif isempty(GS)
    GS = 40;
%     fprintf(1, 'Warning: Set gridscale as parameter, using default [GS = 40] \n');
end

if isfield(e_loc(1), 'x')
    yloc = cell2mat({e_loc.x}); yloc=yloc(:);
    xloc = cell2mat({e_loc.y}); xloc=xloc(:);
else
    e_loc = swa_add2dlocations(e_loc, GS);
    yloc = cell2mat({e_loc.x}); yloc=yloc(:);
    xloc = cell2mat({e_loc.y}); xloc=xloc(:);
end

%% If there is no delay map, or if the involvement map is being plotted...
if isempty(DelayMap)

    % Create the plotting mesh
    XYrange = linspace(1, GS, GS);
    XYmesh  = XYrange(ones(GS,1),:);

    % Check Matlab version for interpolant...
    if exist('scatteredInterpolant', 'file')
        % If its available use the newest function
        F = scatteredInterpolant(xloc,yloc, Data(:), 'natural', 'none');
        ver = 2;
    else
        % Use the old function
        F = TriScatteredInterp(xloc,yloc, Data(:), 'natural');
        ver = 1;
    end

    DelayMap = F(XYmesh, XYmesh')'; % Delay map (with zeros)
end

%% Use the e_loc to project points to a 2D surface
GS = length(DelayMap);
XYrange = linspace(1, GS, GS);
XYmesh = XYrange(ones(GS,1),:);

%% Actual Plot

% Prepare the figure
% Check if there is a figure currently opened; otherwise open a new figure
if isempty(get(0,'children')) || NewFigure == 1
    H.Figure = figure;
    set(H.Figure,...
    'Color',            'w'                 );
    H.CurrentAxes = axes('Position',[0 0 1 1]);
elseif Axes ~= 0
    H.CurrentAxes = Axes;
else
    H.CurrentAxes = gca;
end
%
% Prepare the axes
set(H.CurrentAxes,...
    'XLim',             [1, GS]     ,...
    'YLim',             [1, GS]     ,...
    'NextPlot',         'add'       );

%% Plot the surface interpolation
if PlotSurface == 1
    NumContours = 5;
end

if PlotSurface == 1
    H.Surface = surf(H.CurrentAxes, XYmesh ,XYmesh', zeros(size(DelayMap)), DelayMap');
    set(H.Surface,...
        'EdgeColor',        'none'              ,...
        'FaceColor',        'interp'            ,...
        'HitTest',          'off'               );
end

% If the user specified limits for the Z axis, use those.
if exist('colorlimits', 'var')
  caxis(H.CurrentAxes, colorlimits);
end

% Adjust the contour lines to account for the minimum and maximum difference in values
LevelList   = linspace(min(DelayMap(:)), max(DelayMap(:)), NumContours);


%% Plot the contour map
if PlotContour == 1
    [~,H.Contour] = contourf(H.CurrentAxes, XYmesh,XYmesh',DelayMap');
    set(H.Contour,...
        'LineWidth',        ContourWidth        ,...
        'LevelList',        LevelList           ,...
        'HitTest',          'off'               );
end

%% Prepare the Head, Ears, and Nose (thanks EEGLAB!)
if PlotHead == 1;

    r = GS/2.5;
    center = GS/2;

    % Head
    ang     = 0:0.01:2*pi;
    xp      = center+(r*cos(ang));
    yp      = center+(r*sin(ang));

    % Nose...
    base    = 0.4954;
    basex   = 0.0900;                 % nose width
    tip     = 0.5750;
    tiphw   = 0.02;                   % nose tip half width
    tipr    = 0.005;                  % nose tip rounding

    % Ears...
    q       = .004; % ear lengthening
    EarX  = [0.497-.005  0.510        0.518        0.5299       0.5419       0.54         .547        .532        .510    .489-.005]; % rmax = 0.5
    EarY  = [q+0.0555    q+0.0775     q+0.0783     q+0.0746     q+0.0555     -0.0055      -.0932      -.1313      -.1384  -.1199];

    % Plot the head
    H.Head(1) = plot(H.CurrentAxes, xp, yp);
    H.Head(2) = plot(H.CurrentAxes,...
             center+r*2*[basex;tiphw;0;-tiphw;-basex],center+r*2*[base;tip-tipr;tip;tip-tipr;base]);

    H.Head(3) = plot(H.CurrentAxes,...
                    center+r*2*EarX,center+r*2*EarY);% plot left ear
    H.Head(4) = plot(H.CurrentAxes,...
                    center+r*2*-EarX,center+r*2*EarY);   % plot right ear

    % Set the head properties
    set(H.Head,...
        'Color',            HeadColor           ,...
        'LineWidth',        HeadWidth           ,...
        'HitTest',          'off'               );
end

%% Plot All Channels
if PlotChannels == 1;

    labels    = {e_loc.labels};
    for i = 1:size(labels,2)
        H.Channels(i) = text(xloc(i),yloc(i), '.'         ,...
            'userdata',         char(labels(i))         ,...
            'Parent',           H.CurrentAxes           );
    end

    set(H.Channels                              ,...
        'HorizontalAlignment',  'center'        ,...
        'VerticalAlignment',    'middle'        ,...
        'Color',                'k'             ,...
        'FontSize',             10              ,...
        'FontWeight',           'bold'          );

    set(H.Channels                              ,...
        'buttondownfcn', ...
	    ['tmpstr = get(gco, ''userdata'');'     ...
	     'set(gco, ''userdata'', get(gco, ''string''));' ...
	     'set(gco, ''string'', tmpstr); clear tmpstr;'] );
end

%% Plot Streamlines
if PlotStreams == 1;

    for i = 1:length(Streams)
        if ~isempty(Streams{i})
            pad = linspace(0, GS/streamWidth, length(Streams{i}));
            yp  = [Streams{i}(1,:)-pad, fliplr(Streams{i}(1,:)+pad)];
            xp  = [Streams{i}(2,:)+pad, fliplr(Streams{i}(2,:)-pad)];
            H.PStream(i) = patch(xp,yp,'w', 'Parent', H.CurrentAxes);
        end
    end
    if isfield (H, 'PStream')
        % TODO: fix the java exception when setting the alpha value
%         set(H.PStream(H.PStream > 0),...
        set(H.PStream,...
            'linewidth',    1,...
            'edgecolor',    'k',...
            'facealpha',    0.3,...
            'facecolor',    streamColor);
    end
end

% Adjustments
% square axes
set(H.CurrentAxes, 'PlotBoxAspectRatio', [1, 1, 1]);
% hide the axes
set(H.CurrentAxes, 'visible', 'off');
