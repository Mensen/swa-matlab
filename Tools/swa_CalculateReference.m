function [filtData, Info] = swa_CalculateReference(data, Info, flag_plot)

if nargin < 3
    flag_plot = false;
end

if ~isfield(Info, 'Electrodes');
    error('Error: No electrode information found in Info')
end

if ~isfield(Info.Recording, 'sRate');
    error('no sampling rate information found in Info.Recording');
end

if ~isfield(Info, 'Parameters');
    Info = swa_getInfoDefaults(Info, 'SW', 'envelope');
    fprintf(1, 'Warning: No parameters specified; using defaults');
end

% switch reference parameter to lowercase for compatibility
Info.Parameters.Ref_Method = lower(Info.Parameters.Ref_Method);

fprintf(1, 'Calculating: Canonical wave (%s) \n', Info.Parameters.Ref_Method);

% adjust the electrode coordinates
Th = pi/180*[Info.Electrodes.theta];        % Calculate theta values from x,y,z e_loc
Rd = [Info.Electrodes.radius];              % Calculate radian values from x,y,z e_loc

x = Rd.*cos(Th);                            % Calculate 2D projected X
y = Rd.*sin(Th);                            % Calculate 2D projected Y

% Squeeze the coordinates into a -0.5 to 0.5 box
intrad = min(1.0,max(abs(Rd))); intrad = max(intrad,0.5);
squeezefac = 0.5/intrad;
x = x * squeezefac; y = y * squeezefac;

% plot all the electrodes
if flag_plot
%     figure('color', [0.2, 0.2, 0.2]);
    figure('color', 'w');
    axes('nextplot', 'add', 'Color', 'none');
    axis off;
    % mark the electrodes
    scatter(y, x, 30, ...
        'markerEdgeColor', [0.5, 0.5, 0.5],...
        'markerFaceColor', [0.5, 0.5, 0.5]);
end

switch Info.Parameters.Ref_Method
    
    case 'envelope'
        % Use the e_loc to avoid outer channels in noisy datasets
        if ~isfield(Info.Parameters, 'Ref_UseInside') || Info.Parameters.Ref_UseInside == true
            % Calculate distance from center...
            distances = (x.^2+y.^2).^0.5;
            Info.Parameters.Ref_Electrodes = distances < 0.35; %0.35 out of max 0.5 distance from center
            
            data = data(Info.Parameters.Ref_Electrodes, :);
            
        end
        
        % get the most negative channels for each sample
        % ``````````````````````````````````````````````
        % Sort each sample to find the lowest values for each time point
        rData   = sort(data);
        % How many channels are the 97.5th percentile (or if < 3 = 3)
        nCh     = max(3, floor(length(Info.Electrodes)*0.025));
        % Get the mean of the most negative channels
        % if there are more than 3 channels skip the most negative since it could be artifact
        if nCh > 3
            nData = mean(rData(2:nCh,:));
        else
            nData = mean(rData(1:nCh,:));
        end
        
    case {'square', 'diamond'}
        
        % region parameters
        distance_from_center = 0.2; % x and y distance from the center in each direction
        circle_radius = 0.175;
        
        switch Info.Parameters.Ref_Method
            case 'square'
                RegionCenters = [...
                    -distance_from_center, -distance_from_center, distance_from_center,  distance_from_center;...
                    distance_from_center, -distance_from_center, -distance_from_center, distance_from_center];
            case 'diamond'
                RegionCenters = [...
                    distance_from_center, 0, 0, -distance_from_center;...
                    0, distance_from_center -distance_from_center, 0];
        end
        
        % pre-allocate
        nData = zeros(4, size(data,2));
        Info.Parameters.Ref_Electrodes = false(1, length(x));
        
        for n = 1 : 4 % Each of the four regions
            distances = ((x + RegionCenters(1, n)).^ 2 ...
                + (y + RegionCenters(2, n)).^ 2).^ 0.5;
            Info.Parameters.Ref_Electrodes(n, :) = distances < circle_radius;
            nData(n, :) = mean(data(Info.Parameters.Ref_Electrodes(n, :), :), 1);
        end
        
    case 'grid'
        
        distance_from_center = 0.225; % x and y distance from the center in each direction
        circle_radius = 0.10;
        
        centers_x = meshgrid(-1:1) * distance_from_center;
        centers_y = centers_x';
        
        % pre-allocate
        nData = zeros(9, size(data,2));
        Info.Parameters.Ref_Electrodes = false(1, length(x));
        
        % loop for each region
        for n = 1 : 9
            % calculate distance to center for each electrode
            distances = ((x + centers_x(n)).^ 2 ...
                + (y + centers_y(n)).^ 2).^ 0.5;
            % take electrodes within maximum distance
            Info.Parameters.Ref_Electrodes(n, :) = distances < circle_radius;
            % get the mean data of those electrodes
            nData(n, :) = mean(data(Info.Parameters.Ref_Electrodes(n, :), :), 1);
        end
        
    case 'central'
        
        % region parameters
        circle_radius = 0.175;
        distances = (x.^2 + y.^2).^0.5;
        
        Info.Parameters.Ref_Electrodes = distances < circle_radius;
        fprintf(1, 'Information: Central using %i channels for reference \n',...
            sum(Info.Parameters.Ref_Electrodes));
        % figure('color', 'w'); scatter(y,x); hold on; scatter(y(insideCh),x(insideCh), 'r', 'MarkerFaceColor','r'); axis off;
        nData = mean(data(Info.Parameters.Ref_Electrodes, :), 1);
        
    case 'midline'

        % region parameters
        distance_from_center = 0.25; % y distance from the center in each direction (25%, 50%, 75% of midline)
        circle_radius = 0.125;
        
        RegionCenters = [-distance_from_center,0, +distance_from_center; 0,0,0];
        
        % pre-allocate
        nData = zeros(3,size(data,2));
        Info.Parameters.Ref_Electrodes = false(1, length(x));
        
        for n = 1 : 3 % Each of the three regions
            distances = ((x+RegionCenters(1,n)).^2 + (y+RegionCenters(2,n)).^2).^0.5;
            Info.Parameters.Ref_Electrodes(n, :) = distances < circle_radius; %0.2 captures distinct regions
            nData(n, :) = mean(data(Info.Parameters.Ref_Electrodes(n, :), :), 1);
        end
        
    otherwise
        error('Unrecognised reference method type (check spelling/case)');
end

% plot the regions
if flag_plot
    no_regions = size(Info.Parameters.Ref_Electrodes, 1);
    color_scheme = parula(no_regions);
    for n = 1 : size(Info.Parameters.Ref_Electrodes, 1)
        scatter(y(Info.Parameters.Ref_Electrodes(n, :)), ...
            x(Info.Parameters.Ref_Electrodes(n, :)), 90, ...
            'markerEdgeColor', [0.3, 0.3, 0.3],...
            'markerFaceColor', color_scheme(n, :));
    end
end

% Filter the data
% ~~~~~~~~~~~~~~~
if Info.Parameters.Filter_Apply
    
    % check for necessary defaults
    if ~isfield(Info.Parameters, 'Filter_Method');
        fprintf(1, 'Information: No filter parameters given, suing defaults \n');
        Info.Parameters.Filter_Method = 'Chebyshev';
        Info.Parameters.Filter_hPass = 0.2;
        Info.Parameters.Filter_lPass = 4;
        Info.Parameters.Filter_order = 2;
    end
    
    % filter the data
    fprintf(1, 'Calculation: Applying %s filter for [%0.1f, %0.1f] Hz...', Info.Parameters.Filter_Method, Info.Parameters.Filter_hPass, Info.Parameters.Filter_lPass);
    filtData = swa_filter_data(nData, Info);
    fprintf(1, 'Done \n');
    
else
    % just return the calculated reference
    filtData = nData;
end

% plot 10 seconds of data from references
if flag_plot
    random_sample = randi(Info.Recording.dataDim(2), 1);
    sample_range = random_sample : random_sample + 15 * Info.Recording.sRate - 1;
    time_range = [1:size(sample_range, 2)] / Info.Recording.sRate;
    figure('color', 'w');
    axes('nextplot', 'add');
    for n = 1:size(filtData, 1)
        if strcmp(Info.Parameters.Ref_Method, 'envelope')
            %             plot(time_range, data(:, sample_range),...
            %                 'color', [0.7, 0.7, 0.7]);
            plot(time_range, filtData(n, sample_range),...
                'color', [0.2, 0.2, 0.2],...
                'linewidth', 3);
        else
            plot(time_range, filtData(n, sample_range) - (n - 1) * 60,...
                'linewidth', 2, ...
                'color', color_scheme(n, :));
        end
    end
end

