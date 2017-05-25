function swa_saveOutput(Data, Info, SW, save_name, flag_raw, flag_filtered)
% function to save the wave detection output

% TODO: make generalisable to the different wave types since it is
% currently only compatible with SW by name.

if flag_raw
    % Replace the data with a file pointer if drive space is a concern
    Data.Raw = Info.Recording.dataFile;
else
    fprintf(1, 'Will save all the data into the new Mat file; this may take some time and memory\n');
end

if flag_filtered
    % Save the filtered to a simple binary file (like .fdt)
    filteredName = [Info.Recording.dataFile(1:end-4), '_filtered.fdt'];
    if ~exist(filteredName, 'file')
        swa_save_data(Data.Filtered, filteredName);
    end
    Data.Filtered = filteredName;
elseif isfield(Data, 'Filtered')
    Data = rmfield(Data, 'Filtered');
end

% check for specified name
if isempty(save_name)
    [saveFile, savePath] = uiputfile('*.mat');
    save_name = fullfile(savePath, saveFile);
end

% get the wave type by 
wave_type = inputname(3);

% change variable name according to type
switch wave_type
    case 'SS'
        SS = SW;
    case 'ST'
        ST = SW;
end

% save in a simple mat file
save(save_name, 'Data', 'Info', wave_type, '-mat', '-v7.3');