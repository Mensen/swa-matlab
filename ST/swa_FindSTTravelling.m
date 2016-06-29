function [Info, ST] = swa_FindSTTravelling(Info, ST, indST, flag_progress)
% Calculate the streamlines for each slow wave
% Use a third input to simply recalculate the travelling parameters for a single wave in ST but remember to change the Travelling_Delays parameter first...

if nargin < 4
    flag_progress = 1;
end

if ~isfield(Info.Parameters, 'Travelling_GS');
    Info.Parameters.Travelling_GS = 20; % size of interpolation grid
    fprintf(1, 'Information: Interpolation grid set at 20x20 by default. \n');
    Info.Parameters.Travelling_MinDelay = 40; % minimum travel time (ms)
end

% Check Electrodes for 2D locations (match to grid)
if ~isfield(Info.Electrodes, 'x') || isempty(Info.Electrodes(1).x)
    Info.Electrodes = swa_add2dlocations(Info.Electrodes, Info.Parameters.Travelling_GS);
    fprintf(1,'Calculation: 2D electrode projections (placed in Info.Electrodes). \n');
end

xloc = [Info.Electrodes.x]; xloc=xloc(:);
yloc = [Info.Electrodes.y]; yloc=yloc(:);

% Create the plotting mesh
GS = Info.Parameters.Travelling_GS;
XYrange = linspace(1, GS, GS);
XYmesh = XYrange(ones(GS,1),:);

% Check Matlab version for interpolant...
if exist('scatteredInterpolant', 'file')
    % If its available use the newest function
    F = scatteredInterpolant(xloc,yloc,ST(1).Travelling_Delays(:), 'natural', 'none');
    ver = 2;
else
    % Use the old function
    F = TriScatteredInterp(xloc,yloc,ST(1).Travelling_Delays(:), 'natural');
    ver = 1;
end


% Loop for each ST
if nargin == 3
    loopRange = indST;
    flag_progress = 0;
else
    loopRange = 1:length(ST);
end

if flag_progress
    swa_progress_indicator('initialise', 'Calculating streams');
end

for nST = loopRange
    
    % update progress
    if flag_progress
        swa_progress_indicator('update', nST, length(loopRange));
    end
    
    % take the delays from the structure
    Delays      = ST(nST).Travelling_Delays;
      
    % Interpolate delay map [zeros or nans above...]
    Delays = Delays(:);            % Ensure data is in column format
    
    % Different inputs for scatteredInterpolant and TriScatteredInterp
    if ver == 1
        F.V = Delays;                  % Put new data into the interpolant
    else
        F.Values = Delays;
    end
    
    ST(nST).Travelling_DelayMap = F(XYmesh, XYmesh'); % Delay map (with zeros)
    [u,v] = gradient(ST(nST).Travelling_DelayMap);

    % Check for minimum travel time...
    if max(Delays) < Info.Parameters.Travelling_MinDelay*Info.Recording.sRate/1000
        continue
    end
    
    % Define Starting Point(s) on the GSxGS grid...
    sx = xloc(ST(nST).Channels_Active);
    sy = yloc(ST(nST).Channels_Active);
      
    % Find Streamline(s)
    % Use adstream2 (should optimise by coding entirely in c)
    Streams         = cell(1,length(sx));
    Distances       = cell(1,length(sx));
    for i = 1:length(sx)
        [StreamsBack, DistancesBack,~] = adstream2b(XYrange,XYrange,-u,-v,sx(i),sy(i), cosd(45), 0.1, 1000);
        [StreamsForw, DistancesForw,~] = adstream2b(XYrange,XYrange,u,v,sx(i),sy(i), cosd(45), 0.1, 1000);
        Streams{i}      = [fliplr(StreamsBack), StreamsForw];
        Distances{i}    = [fliplr(DistancesBack), DistancesForw];
    end
             
    % Process and save streamlines...
    Streams(cellfun(@isempty, Streams)) = []; %Remove empty streams
    Distances(cellfun(@isempty, Distances)) = []; %Remove empty streams
    
    if isempty(Streams) % continue if there were no streams found
        continue
    end
    
    % Minimum Distance Threshold (25% of longest path)
    tDist = cellfun(@(x) sum(x), Distances);    %% Plot Functions
    Streams(tDist < max(tDist)/4) = [];
    Distances(tDist < max(tDist)/4) = [];
   
    % Longest displacement
    tDisp = cellfun(@(x) (sum((x(:,1)-x(:,end)).^2))^0.5, Streams); % total displacement
    [~,maxDispId] = max(tDisp);
    ST(nST).Travelling_Streams{1} = Streams{maxDispId};
    
    % Longest distance travelled (if different from displacement)
    tDist = cellfun(@(x) sum(x), Distances);    %% Plot Functions
    [~,maxDistId] = max(tDist);
    if maxDistId ~= maxDispId
        ST(nST).Travelling_Streams{end+1} = Streams{maxDistId};
    end  
        
    % Most different displacement angle compared to longest stream (at least 45 degrees)
    streamAngle = cellfun(@(x) atan2d(x(1,end)- x(1,1),x(2,end)-x(2,1)), Streams);
    [maxAngle,maxAngleId] = max(streamAngle - streamAngle(maxDispId));
    if maxAngle > 45 || maxAngleId ~= maxDispId || maxAngleId ~= maxDistId
        ST(nST).Travelling_Streams{end+1} = Streams{maxAngleId};
    end    
end

if exist('h', 'var')
    delete(h)       % DELETE the waitbar; don't try to CLOSE it.
end