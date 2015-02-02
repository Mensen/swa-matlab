function [output, Info] = swa_batchProcessing(dir_name, pattern, save_ext)
% function to batch process several files with a given extension (e.g.
% _pp.set) using one command.

% inputs
%   dir_name: full path of the directory to search for pattern matches
%   pattern:  string indicating the file names to be processed
%   save_ext: string to add to the file name when saving
%
% outputs
%   output:   if save_output is true, output will be list of summary stats 

if nargin < 3
    save_ext = '';
end

% option to save the file or not (0: no, 1:yes);
save_file = 0; 

% option to save the summary measure outputs
save_output = 1;

% a list of files
fileList = swa_getFiles(dir_name, pattern);

% pre-allocate output structure 
if save_output
    % pre-allocate the output variable
    output = struct(...
        'wave_density',        [], ...
        'wavelength',          [], ...
        'amplitude',           [], ...
        'globality',           [], ...
        'topo_density',        [], ...
        'travel_angle',        []);
else
    output = [];  
end

% loop for each file in the list
for n = 1:length(fileList)

    % split the path and name
    [filePath, fileName, ext] = fileparts(fileList{n});
    [Data, Info] = swa_convertFromEEGLAB([fileName, ext], filePath);

    % get the default parameters
    Info = swa_getInfoDefaults(Info, 'SW', 'envelope');

%     % change the defaults
%     [Data, Info] = swa_changeReference(Data, Info)
%     Info.Parameters.Ref_Method = 'MDC';
    

    % find the waves
    [Data.SWRef, Info]  = swa_CalculateReference (Data.Raw, Info);
    [Data, Info, SW]    = swa_FindSWRef (Data, Info);
    [Data, Info, SW]    = swa_FindSWChannels (Data, Info, SW, 0);
    [Info, SW]          = swa_FindSWTravelling (Info, SW, [], 0);

    % check whether any waves were found/left 
    if length(SW) < 1
        continue;
    elseif length(SW) < 2
        if isempty(SW.Ref_Region)
            continue;
        end
    end

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

    if save_output & ~isempty(SW) 
        % wave density (waves per minute)
        output(n).wave_density = length(SW)/(Info.Recording.dataDim(2)/Info.Recording.sRate/60);

        % mean wavelength
        temp_data = swa_wave_summary(SW, Info, 'wavelengths');
        output(n).wavelength(1) = mean(temp_data);
        output(n).wavelength(2) = std(temp_data);

        % mean amplitude
        temp_data = min([SW.Channels_NegAmp]);
        output(n).amplitude(1) = median(temp_data);
        output(n).amplitude(2) = std(temp_data);
        output(n).amplitude(3) = max(Info.Parameters.Ref_AmplitudeAbsolute);
        
        % mean wave globality
        temp_data = swa_wave_summary(SW, Info, 'globality');
        output(n).globality(1) = mean(temp_data);
        output(n).globality(2) = std(temp_data);

        % wave density
        output(n).topo_density = swa_wave_summary(SW, Info, 'topo_density')';

        % mean travelling angle (need circular means)
        temp_data = swa_wave_summary(SW, Info, 'anglemap') * pi / 180;
            % compute weighted sum of cos and sin of angles
        sum_of_angles = sum(exp(1i*temp_data));
        output(n).travel_angle(1) = angle(sum_of_angles) / pi * 180;

        % angle dispersion
        angle_length = abs(sum_of_angles) / length(temp_data);
        output(n).travel_angle(2) = sqrt(2 * (1 - angle_length)) / pi * 180;

    end

end
