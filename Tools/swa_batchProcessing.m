function swa_batchProcessing(dirName, pattern, save_ext)
% function to batch process several files with a given extension (e.g.
% _pp.set) using one command.

if nargin < 3
    save_ext = '';
end

% option to save the file or not (0: no, 1:yes);
save_file = 0; 

% option to save the summary measure outputs
save_output = 1;

% a list of files
fileList = swa_getFiles(dirName, pattern);

for n = 1:length(fileList)
    
    % split the path and name
    [filePath, fileName, ext] = fileparts(fileList{n});
    [Data, Info] = swa_convertFromEEGLAB([fileName, ext], filePath);
%     [Data, Info, SW] = swa_load_previous([fileName, ext], filePath);

    Info = swa_getInfoDefaults(Info, 'SW', 'envelope');
    
    % change the defaults
    
    
    % find the waves
    [Data.SWRef, Info]  = swa_CalculateReference (Data.Raw, Info);
    [Data, Info, SW]    = swa_FindSWRef (Data, Info);
    [Data, Info, SW]    = swa_FindSWChannels (Data, Info, SW);
    [Info, SW]          = swa_FindSWTravelling (Info, SW);
    
    if save_file
        % save the results
        % ````````````````
        % Replace the data with a file pointer if drive space is a concern
        Data.Raw = Info.Recording.dataFile;
        
        % Save filtered to a simple binary file (like fdt)
        filteredName = [Info.Recording.dataFile(1:end-4), '_filtered.fdt'];
        if ~exist(filteredName, 'file')
            swa_save_data(Data.Filtered, fullfile(filePath, filteredName));
        end
        Data.Filtered = filteredName;
        
        % save the data, info and sw files themselves into simple mat
        saveFile = ['swaFile_', fileName, save_ext, '.mat'];
        save(fullfile(filePath, saveFile), 'Data', 'Info', 'SW', '-mat');
    end
    
    if save_output
        % pre-allocate the output variable
        output = cell(6, 1);
        
        % wave density (waves per minute)
        output{1} = length(SW)/(Info.Recording.dataDim(2)/Info.Recording.sRate/60);
        
        % mean wavelength
        temp_data = swa_wave_summary(SW, Info, 'wavelengths');
        output{2}(1) = mean(temp_data);
        output{2}(2) = std(temp_data);
        
        % mean amplitude
        temp_data = min([SW.Channels_NegAmp]);
        output{3}(1) = median(temp_data);
        output{3}(2) = std(temp_data);

        % mean wave globality
        temp_data = swa_wave_summary(SW, Info, 'globality');
        output{4}(1) = mean(temp_data);
        output{4}(2) = std(temp_data);
        
        % wave density
        output{5} = swa_wave_summary(SW, Info, 'topo_density')';
        
        % mean travelling angle (need circular means)
        temp_data = swa_wave_summary(SW, Info, 'anglemap') * pi / 180;
        % compute weighted sum of cos and sin of angles
        sum_of_angles = sum(exp(1i*temp_data));
        
        output{6}(1) = angle(sum_of_angles) / pi * 180;
        
        % angle dispersion
        angle_length = abs(sum_of_angles) / length(temp_data);
        output{6}(2) = sqrt(2 * (1 - angle_length)) / pi * 180;
        
    end
    
end
    
    
    