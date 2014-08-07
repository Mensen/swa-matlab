function fileList = swa_getFiles(dirName, pattern)

  dirData = dir(dirName);      %# Get the data for the current directory
  dirIndex = [dirData.isdir];  %# Find the index for directories
  fileList = {dirData(~dirIndex).name}';  %'# Get a list of the files
%   if ~isempty(fileList)
%     fileList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
%                        fileList,'UniformOutput',false);
%   end
  
  if ~isempty(fileList)
      fileList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
          fileList,'UniformOutput',false); 	
      matchstart = regexp(fileList, pattern); 	
      fileList = fileList(~cellfun(@isempty, matchstart)); 
  end
  
  subDirs = {dirData(dirIndex).name};  %# Get a list of the subdirectories
  validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories
                                               %#   that are not '.' or '..'
  for iDir = find(validIndex)                  %# Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir});    %# Get the subdirectory path
    fileList = [fileList; swa_getFiles(nextDir, pattern)];  %# Recursively call getAllFiles
  end

end