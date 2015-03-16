function [ChN] = swa_channelNeighbours(eLoc, displayNet)
% Searches for neighbouring channels using triangulation and reports back each channels neighbours

% This file is part of the program ept_TFCE.
% ept_TFCE is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% ept_TFCE is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with ept_TFCE.  If not, see <http://www.gnu.org/licenses/>.

% 11.12.2013
% Fixed error in script for small electrode files where channel list was
% not cleared properly in each iteration of finding neighbours...

if nargin < 2
    displayNet = 0; %set to 1 if you want net to be displayed in a figure.
end

nCh = length(eLoc);

indices = 1:nCh;

x = [eLoc(indices).X ]'; % Gets the X,Y, and Z values from loc_file
y = [eLoc(indices).Y ]';
z = [eLoc(indices).Z ]';

vertices = [x,y,z];

%% [X,Y] = bst_project_2d(vertices(:,1), vertices(:,2), vertices(:,3));

        z2 = z - max(z);

	%% [TH,PHI,R] = cart2sph(x, y, z) // [az,elev,r] = cart2sph(x,y,z)

        hypotxy = hypot(x,y);
        R = hypot(hypotxy,z2);
        PHI = atan2(z2,hypotxy);
        TH = atan2(y,x);

        % Remove the too small values for PHI
        PHI(PHI < 0.001) = 0.001;

        % Flat projection
        R2 = R ./ cos(PHI) .^ .2;

    %% [X,Y] = pol2cart(TH,R2) // [x,y,z] = pol2cart(th,r,z)

        X = R2.*cos(TH);
        Y = R2.*sin(TH);

%% bfs_center = bst_bfs(vertices)' // [ HeadCenter, Radius ] = bst_bfs( Vertices )

    mass = mean(vertices);
    diffvert = bsxfun(@minus, vertices, mass); % originally uses bst_bsxfun but only for older Matlab versions
    R0 = mean(sqrt(sum(diffvert.^2, 2)));
    % Optimization
    vec0 = [mass,R0];
    minn = fminsearch(@dist_sph, vec0, [], vertices);
    HeadCenter = minn(1:end-1); % 3x1

    
coordC = bsxfun(@minus, vertices, HeadCenter);
coordC = bsxfun(@rdivide, coordC, sqrt(sum(coordC.^2,2)));
coordC = bsxfun(@rdivide, coordC, sqrt(sum(coordC.^2,2)));
% Tesselation of the sensor array
faces  = convhulln(coordC);


%% Remove unnecessary triangles...

% Get border of the representation
border = convhull(X,Y);
%plot(X(border),Y(border),'r-',X,Y,'b+')

% Keep faces inside the border
iInside = ~(ismember(faces(:,1),border) & ismember(faces(:,2),border)& ismember(faces(:,3),border));
faces   = faces(iInside, :);

    my_norm = @(v)sqrt(sum(v .^ 2, 2)); % creates an object
    % Get coordinates of vertices for each face
    vertFacesX = reshape(vertices(reshape(faces,1,[]), 1), size(faces));
    vertFacesY = reshape(vertices(reshape(faces,1,[]), 2), size(faces));
    vertFacesZ = reshape(vertices(reshape(faces,1,[]), 3), size(faces));
    % For each face : compute triangle perimeter
    triSides = [my_norm([vertFacesX(:,1)-vertFacesX(:,2), vertFacesY(:,1)-vertFacesY(:,2), vertFacesZ(:,1)-vertFacesZ(:,2)]), ...
                my_norm([vertFacesX(:,1)-vertFacesX(:,3), vertFacesY(:,1)-vertFacesY(:,3), vertFacesZ(:,1)-vertFacesZ(:,3)]), ...
                my_norm([vertFacesX(:,2)-vertFacesX(:,3), vertFacesY(:,2)-vertFacesY(:,3), vertFacesZ(:,2)-vertFacesZ(:,3)])];
    triPerimeter = sum(triSides, 2);
    % Threshold values
    thresholdPerim = mean(triPerimeter) + 3 * std(triPerimeter);
    % Apply threshold
    faces(triPerimeter > thresholdPerim, :) = [];

    
%% Display Net
if displayNet == 1;

    figure( 'Color',       'w'     ,...
                'Position',    [50,50, 500, 500]  );

        axes  ( 'Color',      'w' );   

        FaceColor = [.5 .5 .5];
        EdgeColor = [0 0 0];
        FaceAlpha = .9;
        LineWidth = 1;

        hNet = patch('Vertices',        vertices, ...
                     'Faces',           faces, ...
                     'FaceVertexCData', repmat([1 1 1], [length(vertices), 1]), ...
                     'Marker',          'o', ...
                     'LineWidth',       LineWidth, ...
                     'FaceColor',       FaceColor, ...
                     'FaceAlpha',       FaceAlpha, ...
                     'EdgeColor',       EdgeColor, ...
                     'EdgeAlpha',       1, ...
                     'MarkerEdgeColor', [0 0 0], ...
                     'MarkerFaceColor', 'flat', ...
                     'MarkerSize',      12, ...
                     'BackfaceLighting', 'lit', ...
                     'Tag',             'SensorsPatch');
        material([ 0.5 0.50 0.20 1.00 0.5 ])
        lighting phong
    % Set Constant View Angle
    view(48,15);
    axis equal
    cameratoolbar('Show')
    rotate3d on
    axis off
       
end

% loop through all the channels
output = cell(nCh,1);
for i = 1:nCh
    
    % reset the counting variable for the 'if statement' for every channel
    count = 1;
    ch = [];
    
    % look through all the faces one at a time
    for j = 1:length(faces)
        
       tri = faces(j,:);
       
       % see if that particular channel is a member of that face
       if ismember(i,tri)
           
           % if it is then record other channels along with it
           ch(count,:)   = tri;
           count         = count + 1;
           
       end

    end
    
    % eliminate the repeating variables and save the result in a cell
    output{i} = unique(ch(:))';
    
end

nz=max(cellfun(@numel,output));
ChN=cell2mat(cellfun(@(a) [a,zeros(1,nz-numel(a))],output,'uni',false));

end
    %%
    function d = dist_sph(vec,sensloc)
        R = vec(end);
        center = vec(1:end-1);
        % Average distance between the center if mass and the electrodes
        diffvert = bsxfun(@minus, sensloc, center);
        d = mean(abs(sqrt(sum(diffvert.^2,2)) - R));
    end








