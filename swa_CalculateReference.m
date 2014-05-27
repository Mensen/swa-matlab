function [filtData, Info] = swa_CalculateReference(Data, Info)

if ~isfield(Info, 'Electrodes');
	error('Error: No electrode information found in Info')
end

if ~isfield(Info, 'sRate');
    Info.sRate = 250;
end

if ~isfield(Info.Parameters, 'Ref_Method');
    Info.Parameters.Method = 'Envelope';
    fprintf(1, 'Warning: No method specified, default to Negative Envelope Method');
end

switch Info.Parameters.Ref_Method
    
    case 'Envelope'
        
    %% Use the e_loc to avoid outer channels in noisy datasets
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
        
        Data = Data(insideCh,:);
        
    end
    
    %% Get the most negative channels for each sample
    rData   = sort(Data);                             % Sort each sample to find the lowest values for each time point
    nCh     = floor(length(Info.Electrodes)*0.025);   % How many channels are the 97.5th percentile
    nData   = mean(rData(2:nCh,:));                   % Get the mean of the most negative channels (leave most negative if artifact)
    
    case 'MDC'
    
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
        
        nData = zeros(4,size(Data,2));              
        for i = 1:4 % Each of the four regions
            distances = ((x+RegionCenters(1,i)).^2 + (y+RegionCenters(2,i)).^2).^0.5;
            insideCh = distances<0.175; %0.2 captures distinct regions
            % figure('color', 'w'); scatter(y,x); hold on; scatter(y(insideCh),x(insideCh), 'r', 'MarkerFaceColor','r'); axis off;
            nData(i,:) = mean(Data(insideCh,:));            
        end
    
    case 'Central'
        
        % Get the electrodes in the four regions
        Th = pi/180*[Info.Electrodes.theta];        % Calculate theta values from x,y,z e_loc
        Rd = [Info.Electrodes.radius];              % Calculate radian values from x,y,z e_loc
        
        x = Rd.*cos(Th);                            % Calculate 2D projected X
        y = Rd.*sin(Th);                            % Calculate 2D projected Y
        
        % Squeeze the coordinates into a -0.5 to 0.5 box
        intrad = min(1.0,max(abs(Rd))); intrad = max(intrad,0.5); squeezefac = 0.5/intrad;
        x = x*squeezefac; y = y*squeezefac;
        
        distances = (x.^2 + y.^2).^0.5;
        insideCh = distances<0.15;
        fprintf(1, 'Information: Central using %i channels for reference \n', sum(insideCh));
        % figure('color', 'w'); scatter(y,x); hold on; scatter(y(insideCh),x(insideCh), 'r', 'MarkerFaceColor','r'); axis off;
        nData = mean(Data(insideCh,:));
        
        
    case 'Midline'

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
        
        nData = zeros(3,size(Data,2));              
        for i = 1:3 % Each of the three regions
            distances = ((x+RegionCenters(1,i)).^2 + (y+RegionCenters(2,i)).^2).^0.5;
            insideCh = distances<0.1; %0.2 captures distinct regions
%             figure('color', 'w'); scatter(y,x); hold on; scatter(y(insideCh),x(insideCh), 'r', 'MarkerFaceColor','r'); axis off;
            nData(i,:) = mean(Data(insideCh,:));            
        end
    
end
%% Filter the new data to 'baseline correct' it so there are DZCs

if Info.Parameters.Filter_Apply
    
    if ~isfield(Info.Parameters, 'Filter_Method');
        fprintf(1, 'Information: No filter parameters given, suing defaults \n');
        Info.Parameters.Filter_Method = 'Chebyshev';
        Info.Parameters.Filter_hPass = 0.2;
        Info.Parameters.Filter_lPass = 4;
        Info.Parameters.Filter_order = 2;
    end
    
    
    fprintf(1, 'Calculation: Applying %s filter for [%0.1f, %0.1f] Hz...', Info.Parameters.Filter_Method, Info.Parameters.Filter_hPass, Info.Parameters.Filter_lPass);
    
    switch Info.Parameters.Filter_Method
        case 'Chebyshev'
            Wp=[Info.Parameters.Filter_hPass Info.Parameters.Filter_lPass]/(Info.sRate/2); % Filtering parameters
            Ws=[Info.Parameters.Filter_hPass/5 Info.Parameters.Filter_lPass*2]/(Info.sRate/2); % Filtering parameters
            Rp=3;
            Rs=10;
            [n, Wn]=cheb2ord(Wp,Ws,Rp,Rs);
            [bbp,abp]=cheby2(n,Rs,Wn); % Loses no more than 3 dB in pass band and has at least 10 dB attenuation in stop band
            % fprintf(1, 'Filtering Reference Channel(s)...');
            filtData=filtfilt(bbp, abp, nData')';
            % fprintf(1, 'Done. \n');
            
        case 'Buttersworth'
            fhc = Info.Parameters.Filter_hPass/(Info.sRate/2);
            flc = Info.Parameters.Filter_lPass/(Info.sRate/2);
            [b1,a1] = butter(Info.Parameters.Filter_order,fhc,'high');
            [b2,a2] = butter(Info.Parameters.Filter_order,flc,'low');
            
            % fprintf(1, 'Filtering Reference Channel(s)...');
            filtData = filtfilt(b1, a1, nData');
            filtData = (filtfilt(b2, a2, filtData))';
            % fprintf(1, 'Done. \n');
    end
    
    fprintf(1, 'Done \n');
    
else
    
    filtData = nData;
end
    
%     figure('color', 'w'); plot(nData(1,1:5000)); hold on; plot(filtData(1,1:5000),'r', 'linewidth', 3);
    