function swa_batchProcessing(dirName, pattern)

% a list of files
fileList = swa_getFiles(dirName, pattern);

for n = 1:length(fileList)
    
    % split the path and name
    [filePath, fileName, ext] = fileparts(fileList{n});
    [Data, Info] = swa_convertFromEEGLAB([fileName, ext], filePath);

    Info = swa_getInfoDefaults(Info, 'SW', 'envelope');
    
    % change the defaults
    
    
    % find the waves
    [Data.SWRef, Info]  = swa_CalculateReference (Data.Raw, Info);
    [Data, Info, SW]    = swa_FindSWRef (Data, Info);
    [Data, Info, SW]    = swa_FindSWChannels (Data, Info, SW);
    [Info, SW]          = swa_FindSWTravelling (Info, SW);
    
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
    saveFile = ['swaFile_', fileName, '.mat'];
    save(fullfile(filePath, saveFile), 'Data', 'Info', 'SW', '-mat');
    
end
    
    
    