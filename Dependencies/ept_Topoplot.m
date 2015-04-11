function H = ept_Topoplot(V, e_loc, varargin)
%% New Topoplot Function (ept)
%
% Usage H = ept_Topoplot(V, e_loc, varargin)
%
% V is a single column vector of the data to be plotted (must have the length of the number of channels)
% e_loc is the EEGLAB generated structure containing all information about electrode locations
%
%
% Optional Arguments:
% HeadWidth = Value   - Controls the width of the lines used in the drawing of the head [Default: 2.5]
% 
% NewFigure = 0/1     - Controls whether a new figure is created (1) or the topoplot is placed in the currently active axes (0) [Default: 0]

% This file is part of the program ept_ResultViewer.
% ept_ResultViewer is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% ept_ResultViewer is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with ept_ResultViewer.  If not, see <http://www.gnu.org/licenses/>.

%% Revision History
% Version 1.0
% 12.12.2012
%% Set defaults
GridScale           = 100;          % Determines the quality of the image
HeadWidth           = 2.5;
HeadColor           = [0,0,0];
ContourWidth        = 0.5;
NumContours         = 12;

PlotContour         = 1;            % Determines whether the contour lines are drawn
PlotSurface         = 0;            % Determines whether the surface is drawn
PlotHead            = 1;            % Determines whether the head is drawn 
PlotChannels        = 1;            % Determines whether the channels are drawn
PlotSigChannels     = 0;            % Determines whether significant channels are plotted separately

SigThreshold        = 0.05;
PValues             = [];

NewFigure           = 0;            % 0/1 - Whether to explicitly draw a new figure for the topoplot
Axes                = 0;

if isempty(V)
    fprintf(1, 'Warning: Input data was found to be empty \n');
    return;
end

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
        case 'contourwidth'
            ContourWidth        = Value;
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
        case 'plotsigchannels'
            PlotChannels        = Value;
        case 'plothead'
            PlotHead            = Value;
        case 'pvalues'
            PValues             = Value;         
        otherwise
            display (['Unknown parameter setting: ' Param])
    end
  end
end

%% Adjust Settings based on Arguments

if nansum(V(:)) == 0 
    PlotContour = 0;
end

% Overwrite number of contours if the interpolated surface is drawn
if PlotSurface == 1
    PlotContour = 0; % Overwrite contours for surface
    NumContours = 5;
end

if PlotSigChannels == 1 && ~isempty(PValues)
    display('Asked to plot significant channels without the addition of the p-values.');
    PlotSigChannels = 0;
end

% Adjust the contour lines to account for the minimum and maximum difference in values
LevelList   = linspace(min(V(:)), max(V(:)), NumContours);


%% Use the e_loc to project points to a 2D surface

Th = pi/180*[e_loc.theta];        % Calculate theta values from x,y,z e_loc
Rd = [e_loc.radius];              % Calculate radian values from x,y,z e_loc

x = Rd.*cos(Th);                            % Calculate 2D projected X
y = Rd.*sin(Th);                            % Calculate 2D projected Y

% Squeeze the coordinates into a -0.5 to 0.5 box
intrad = min(1.0,max(abs(Rd))); intrad = max(intrad,0.5); squeezefac = 0.5/intrad;

x = x*squeezefac; y = y*squeezefac;

%% Create the plotting mesh

Xq = linspace(-0.5, 0.5, GridScale);
XYq = Xq(ones(GridScale,1),:);

%% Create the interpolation function
x=x(:); y=y(:); V=V(:);                     % Ensure data is in column format
F = TriScatteredInterp(x,y,V, 'natural');
Zi = F(XYq', XYq);

%% Actual Plot

% Prepare the figure
% Check if there is a figure currently opened; otherwise open a new figure
if isempty(get(0,'children')) || NewFigure == 1
    H.Figure = figure;
    set(H.Figure,...
    'Color',            'w'                 ,...
    'Renderer',         'painters'            );

    H.CurrentAxes = axes('Position',[0 0 1 1]);
elseif Axes ~= 0
    H.CurrentAxes = Axes;
else
    H.CurrentAxes = gca;
end
% 
% Prepare the axes
set(H.CurrentAxes,...
    'XLim',             [-0.5, 0.5]         ,...
    'YLim',             [-0.5, 0.5]         ,...
    'NextPlot',         'add'               );

%% Plot the contour map
if PlotContour == 1
    [~,H.Contour] = contourf(H.CurrentAxes, XYq,XYq',Zi);
    set(H.Contour,...
        'EdgeColor',        'none'              ,...
        'LineWidth',        ContourWidth        ,...
        'Color',            'k'                 ,...
        'LevelList',        LevelList           ,...
        'HitTest',          'off'               );
end

%% Plot the surface interpolation
if PlotSurface == 1
    unsh = (GridScale+1)/GridScale; % un-shrink the effects of 'interp' SHADING
    H.Surface = surface(XYq*unsh ,XYq'*unsh, zeros(size(Zi)), Zi);
    set(H.Surface,...
        'EdgeColor',        'none'              ,...
        'FaceColor',        'interp'            ,...
        'HitTest',          'off'               );
end

%% Prepare the Head, Ears, and Nose (thanks EEGLAB!)
if PlotHead == 1;
    sf = 0.333/0.5; %Scaling factor for the headsize

    % Head
    angle   = 0:1:360;
    datax   = (cos(angle*pi/180))/3;
    datay   = (sin(angle*pi/180))/3; 

    % Nose...
    base    = 0.4954;
    basex   = 0.0900;                 % nose width
    tip     = 0.5750; 
    tiphw   = 0.02;                   % nose tip half width
    tipr    = 0.005;                  % nose tip rounding

    % Ears...
    q       = .04; % ear lengthening
    EarX  = [.497-.005  .510        .518        .5299       .5419       .54         .547        .532        .510    .489-.005]; % rmax = 0.5
    EarY  = [q+.0555    q+.0775     q+.0783     q+.0746     q+.0555     -.0055      -.0932      -.1313      -.1384  -.1199];

    % Plot the head
    H.Head(1) = plot(H.CurrentAxes, datax, datay);
    H.Head(2) = plot(H.CurrentAxes,...
             [basex;tiphw;0;-tiphw;-basex]*sf,[base;tip-tipr;tip;tip-tipr;base]*sf);
    H.Head(3) = plot(H.CurrentAxes,...
                    EarX*sf,EarY*sf);% plot left ear
    H.Head(4) = plot(H.CurrentAxes,...
                    -EarX*sf,EarY*sf);   % plot right ear

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
        H.Channels(i) = text(y(i),x(i), '.'         ,...
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

% Plot the significant channels separately
% if PlotSigChannels == 1;
%     
%     SigId    = find(PValues(:,Sample)<SigThreshold); % Significant Channels
%     set(hChannels(SigId{1})                     ,...
%         'String',               '+'             ); 
%     
% end

% Adjustments
axis square
axis off
colormap(jet)


