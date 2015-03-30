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

switch Info.Parameters.Ref_Method
    
    case 'envelope'
        
    % Use the e_loc to avoid outer channels in noisy datasets
    if ~isfield(Info.Parameters, 'Ref_UseInside') || Info.Parameters.Ref_UseInside == true
        
        Th = pi/180*[Info.Electrodes.theta];        % Calculate theta values from x,y,z e_loc
        Rd = [Info.Electrodes.radius];              % Calculate radian values from x,y,z e_loc
        
        x = Rd.*cos(Th);                            % Calculate 2D projected X
        y = Rd.*sin(Th);                            % Calculate 2D projected Y
        
        % Squeeze the coordinates into a -0.5 to 0.5 box
        intrad = min(1.0,max(abs(Rd))); intrad = max(intrad,0.5); squeezefac = 0.5/intrad;
        x = x*squeezefac; y = y*squeezefac;
        
        % Calculate distance from center...
        distances = (x.^2+y.^2).^0.5;
        insideCh = distances<0.35; %0.35 out of max 0.5 distance from center
        
        data = data(insideCh,:);
        
    end

    % get the most negative channels for each sample
    % ``````````````````````````````````````````````
    fprintf(1, 'Calculation: Negative Envelope \n');
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

    case 'mdc'
        % Get the electrodes in the four regions
        Th = pi/180*[Info.Electrodes.theta];        % Calculate theta values from x,y,z e_loc
        Rd = [Info.Electrodes.radius];              % Calculate radian values from x,y,z e_loc

        x = Rd.*cos(Th);                            % Calculate 2D projected X
        y = Rd.*sin(Th);                            % Calculate 2D projected Y
        
        % Squeeze the coordinates into a -0.5 to 0.5 box
        intrad = min(1.0,max(abs(Rd))); intrad = max(intrad,0.5); squeezefac = 0.5/intrad;
        x = x*squeezefac; y = y*squeezefac;
        
        r = 0.2; % x and y distance from the center in each direction
        RegionCenters = [-r, -r, r,  r;...
                          r, -r, -r, r];
        
        nData = zeros(4,size(data,2));  
        if flag_plot
            figure('color', [0.2, 0.2, 0.2]);
            axes('nextplot', 'add', 'Color', 'none');
            axis off;
            % mark the electrodes
            scatter(y, x,...
                'markerEdgeColor', [0.5, 0.5, 0.5],...
                'markerFaceColor', [0.5, 0.5, 0.5]);
        end
        for i = 1:4 % Each of the four regions
            distances = ((x+RegionCenters(1,i)).^2 + (y+RegionCenters(2,i)).^2).^0.5;
            insideCh = distances < 0.175; % 0.2 captures distinct regions
            nData(i,:) = mean(data(insideCh, :));
            % plot the regions
            if flag_plot;
                scatter(y(insideCh),x(insideCh), 90, ...
                    'markerEdgeColor', [0.8, 0.8, 0.8],...
                    'markerFaceColor', [0.8, 0.8, 0.8]);
            end
        end
    
    case 'central'
        
        % Get the electrodes in the four regions
        Th = pi/180*[Info.Electrodes.theta];        % Calculate theta values from x,y,z e_loc
        Rd = [Info.Electrodes.radius];              % Calculate radian values from x,y,z e_loc
        
        x = Rd.*cos(Th);                            % Calculate 2D projected X
        y = Rd.*sin(Th);                            % Calculate 2D projected Y
        
        % Squeeze the coordinates into a -0.5 to 0.5 box
        intrad = min(1.0,max(abs(Rd))); intrad = max(intrad,0.5); squeezefac = 0.5/intrad;
        x = x*squeezefac; y = y*squeezefac;
        
        distances = (x.^2 + y.^2).^0.5;
        insideCh = distances < 0.15;
        fprintf(1, 'Information: Central using %i channels for reference \n', sum(insideCh));
        % figure('color', 'w'); scatter(y,x); hold on; scatter(y(insideCh),x(insideCh), 'r', 'MarkerFaceColor','r'); axis off;
        nData = mean(data(insideCh,:));
        
        
    case 'midline'

        % Get the electrodes in the three regions
        Th = pi/180*[Info.Electrodes.theta];        % Calculate theta values from x,y,z e_loc
        Rd = [Info.Electrodes.radius];              % Calculate radian values from x,y,z e_loc
        
        x = Rd.*cos(Th);                            % Calculate 2D projected X
        y = Rd.*sin(Th);                            % Calculate 2D projected Y
        
        % Squeeze the coordinates into a -0.5 to 0.5 box
        intrad = min(1.0,max(abs(Rd))); intrad = max(intrad,0.5); squeezefac = 0.5/intrad;
        x = x*squeezefac; y = y*squeezefac;
        
        r = 0.25; % y distance from the center in each direction (25%, 50%, 75% of midline)
        RegionCenters = [-r,0, +r; 0,0,0];
        
        nData = zeros(3,size(data,2));              
        for i = 1:3 % Each of the three regions
            distances = ((x+RegionCenters(1,i)).^2 + (y+RegionCenters(2,i)).^2).^0.5;
            insideCh = distances<0.1; %0.2 captures distinct regions
%             figure('color', 'w'); scatter(y,x); hold on; scatter(y(insideCh),x(insideCh), 'r', 'MarkerFaceColor','r'); axis off;
            nData(i,:) = mean(data(insideCh,:));            
        end

    otherwise
        error('Unrecognised reference method type (check spelling/case)');
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
    sample_range = random_sample : random_sample + 4 * Info.Recording.sRate - 1;
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
            plot(time_range, filtData(n, sample_range) - (n - 1) * 40,...
                'linewidth', 2);
        end
    end
end
    
