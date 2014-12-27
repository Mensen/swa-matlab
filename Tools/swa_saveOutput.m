function swa_saveOutput(Data, Info, SW, save_name, flag_raw, flag_filtered)
% function to save the wave detection output

if flag_raw
    % Replace the data with a file pointer if drive space is a concern
    Data.Raw = Info.Recording.dataFile;
end

if flag_filtered
    % Save the filtered to a simple binary file (like .fdt)
    filteredName = [Info.Recording.dataFile(1:end-4), '_filtered.fdt'];
    if ~exist(filteredName, 'file')
        swa_save_data(Data.Filtered, filteredName);
    end
    Data.Filtered = filteredName;
else
    Data = rmfield(Data, 'Filtered');
end

% check for specified name
if isempty(save_name)
    [saveFile, savePath] = uiputfile('*.mat');
else
    savePath = pwd;
end

% save in a simple mat file
save([savePath, saveFile], 'Data', 'Info', 'SW', '-mat');