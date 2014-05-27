function [SW,Info] = swa_FindSWStreams(SW,Info)
% Calculate the streamlines for each slow wave

if ~isfield(Info.Parameters, 'Stream_GS');
    Info.Parameters.Stream_GS = 20; % size of interpolation grid
    fprintf(1,'Information: Interpolation grid set at 20x20 by default. \n');
    Info.Parameters.Stream_MinDelay = 40; % minimum travel time (ms)
end

%% Check Electrodes for 2D locations (match to grid)
Info.Electrodes = swa_add2dlocations(Info.Electrodes, Info.Parameters.Stream_GS);
fprintf(1,'Calculation: 2D electrode projections (Info.Electrodes). \n');

xloc = [Info.Electrodes.x]; xloc=xloc(:);
yloc = [Info.Electrodes.y]; yloc=yloc(:);

%% Create the plotting mesh
GS = Info.Parameters.Stream_GS; 
XYrange = linspace(1, GS, GS);
XYmesh = XYrange(ones(GS,1),:);
F = TriScatteredInterp(xloc,yloc,SW(1).Travelling_Delays(:), 'natural');      % No speed difference in methods...

%% Loop for each SW
h = waitbar(0,'Please wait...', 'Name', 'Finding Streams...');
for nSW = 1:length(SW)
    
    Delays      = SW(nSW).Travelling_Delays;
    
    % Check for minimum travel time...
    if max(Delays) < Info.Parameters.Stream_MinDelay * Info.sRate/1000
        continue
    end
    
    %% Interpolate delay map [zeros or nans above...]
    Delays = Delays(:);            % Ensure data is in column format
    F.V = Delays;                  % Put new data into the interpolant
    SW(nSW).Travelling_DelayMap = F(XYmesh, XYmesh'); % Delay map (with zeros)
    [u,v] = gradient(SW(nSW).Travelling_DelayMap);

    %% Define Starting Point(s) on the GSxGS grid...
    sx = xloc(SW(nSW).Travelling_Delays<2);
    sy = yloc(SW(nSW).Travelling_Delays<2);
      
    %% Find Streamline(s)
    % stream2 results in NaN values in streams and also tiny repetitions of coordinates.
%     SW(nSW).Vector = stream2(XY,XY',u,v,sx,sy, [0.2, 100]); % max stepsize 100 to avoid too many NaNs
    
    % But mmstream2 is 4 times slower and still leaves NaNs (stream2 uses mex)!
%     SW(nSW).Vector = mmstream2(XY,XY',u,v,sx,sy, 'start', 0.2); % max stepsize 100 to avoid too many NaNs
    
    % Use adstream2
    Streams         = cell(1,length(sx));
    Distances       = cell(1,length(sx));
    for i = 1:length(sx)
        [Streams{i},Distances{i},~] = adstream2b(XYrange,XYrange,u,v,sx(i),sy(i), cosd(45), 0.1, 1000);
    end
       
    % Problems
    % P: Border origins are not calculable because border u/v gradients are NaN
    % A1: Make neighbour channels -1 and recalculate
    % A2: Edit adstream to make it more compatible
    % P: Streams stop at zero gradients
       
    %% Process and save streamlines...
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
    SW(nSW).Travelling_Streams{1} = Streams{maxDispId};
    
    % Longest distance travelled (if different from displacement)
    tDist = cellfun(@(x) sum(x), Distances);    %% Plot Functions
    [~,maxDistId] = max(tDist);
    if maxDistId ~= maxDispId
        SW(nSW).Travelling_Streams{end+1} = Streams{maxDistId};
    end  
        
    % Most different displacement angle compared to longest stream (at least 45 degrees)
    streamAngle = cellfun(@(x) atan2d(x(1,end)- x(1,1),x(2,end)-x(2,1)), Streams);
    [maxAngle,maxAngleId] = max(streamAngle - streamAngle(maxDispId));
    if maxAngle > 45 || maxAngleId ~= maxDispId || maxAngleId ~= maxDistId
        SW(nSW).Travelling_Streams{end+1} = Streams{maxAngleId};
    end
    
    %% Plot Functions

%     H.Figure    = figure('color','w'); % set axes CLim to 0.5 to avoid all white delay = 1
%     H.Contour   = contourf(XYmesh,XYmesh',SW(nSW).Delay_Map,10, 'edgecolor', 'none');
%     camroll(90) % rotate counter-clockwise
%     
% %     H.Image     = imagesc(SW(nSW).Delay_Map);
%     
%     hold on
%     axis ij % invert the y axis
%     axis square
%     axis off
%     hold on
%     colormap(flipud(hot))
%     % channel plot
%     H.Channels = plot(xloc,yloc,'k.');
%     H.Starts   = plot(sx,sy,'ko', 'linewidth', 2);
% 
% %     H.Streams = plot(SW(nSW).Vector{1}(1,:), SW(nSW).Vector{1}(2,:));
% %     set(H.Streams,'color','k', 'linewidth', 4);
%     
% %     for i = 1:length(SW(nSW).Vector)
% %         if ~isempty(SW(nSW).Vector{i})
% %             H.Streams(i) = plot(SW(nSW).Vector{i}(1,:), SW(nSW).Vector{i}(2,:));
% %         end
% %     end
% %     set(H.Streams(H.Streams>0), 'color','k', 'linewidth', 2);
%     
%     % Plot Patches for Streams
%     H.PStream = [];
%     for i = 1:length(SW(nSW).Streams)
%         if ~isempty(SW(nSW).Streams{i})
%             pad = linspace(0,Info.Stream_Parameters.GS/50,length(SW(nSW).Streams{i}));
%             xp = [SW(nSW).Streams{i}(1,:)-pad, fliplr(SW(nSW).Streams{i}(1,:)+pad)];
%             yp = [SW(nSW).Streams{i}(2,:)+pad, fliplr(SW(nSW).Streams{i}(2,:)-pad)];
%             H.PStream(i) = patch(xp,yp,'w');
%         end
%     end
%     set(H.PStream(H.PStream>0),...
%         'linewidth',    2,...
%         'edgecolor',    'w',...
%         'facecolor',    'b',...
%         'facealpha',    0.5);%     set(H.Streams(1),'color','k', 'linewidth', 4);

    %% Update waitbar
    waitbar(nSW/length(SW),h,sprintf('Slow Wave %d of %d',nSW, length(SW)))

end
delete(h)       % DELETE the waitbar; don't try to CLOSE it.
