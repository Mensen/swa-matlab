function [eloc, id] = swa_subsampleChannels(eloc, n, flag_plot)
% Calculating sparser electrode arrays from existing set
% E.g. subsample 256 electrode array down to 128 channels

% Looks for the smallest distances between any two electrodes and 
% iteratively eliminates the electrode with the shortest distance to 
% its neighbours until the desired number of channels are reached

% Input the electode location file and the desired channels
% Outputs the new location file with the channel ids corresponding 
% to the channels kept from the original

if nargin < 3
    flag_plot = 1;
end

% add 2d locations for plotting
if ~isfield(eloc, 'x')
    eloc = swa_add2dlocations(eloc);
end

% copy the original
original = eloc;
index = 1:length(original);

i = length(eloc);
while i > n-1
    
    % Get all the 3d vertices together
    x = [eloc.X];
    y = [eloc.Y];
    z = [eloc.Z];
    vertices = [x',y',z'];

    % calculate the distances from each electrode to all others
    dist = squareform(pdist(vertices, 'euclidean'));

        % make the diagonal higher so not found as the minimum
    [m, ~] = size(dist);
    dist(1:m+1:end) = max(dist(:));
   
    % find the channels with the smallest distance between them
    minDist = min(dist(:));
    [r,c] = find(dist == minDist);
    
    % find out which of those channels has the higher closer neighbours
    chSorted = sort(dist(r,:),2);
    chNDist  = sum(chSorted(:,1:6),2);
    chId = chNDist ==  min(chNDist);

    eloc(r(chId)) = [];
    index(r(chId)) = [];
    
    i = length(eloc);
        
end

id = false(1, length(original));
id(index) = true;

% plot the original and the new locations
if flag_plot
    figure('color', 'w')
    plot([original.y],[original.x], '.', 'color', [0.8 0.8 0.8], 'markersize', 15)
    hold all;
    plot([eloc.y],[eloc.x], 'b.', 'markersize', 20)

    axis off
end
