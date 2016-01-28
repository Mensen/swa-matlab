function fileList = swa_getFiles(dir_name, pattern)
% function to recursively find files matching a certain pattern

% Get the data for the current directory
dirData = dir(dir_name);
% Find the index for directories
dirIndex = [dirData.isdir];
% Get a list of the files
fileList = {dirData(~dirIndex).name}';

if ~isempty(fileList)
    % Prepend path to files
    fileList = cellfun(@(x) fullfile(dir_name,x),...
        fileList,'UniformOutput',false);
    
    % check if pattern in string or cell array
    if ischar(pattern)
        matchstart = regexp(fileList, pattern);
        fileList = fileList(~cellfun(@isempty, matchstart));
            
    elseif iscell(pattern) 
        % recursively match to each pattern consecutively
        for n = 1 : length(pattern)
            matchstart = regexp(fileList, pattern{n});
            fileList = fileList(~cellfun(@isempty, matchstart));
        end
        
    else
        frintf(1, 'pattern must either be a string or cell of strings \n')
        fileList = [];
        return        
        
    end
    
end

% Get a list of the subdirectories
subDirs = {dirData(dirIndex).name};
% Find index of subdirectories that are not '.' or '..'
validIndex = ~ismember(subDirs,{'.','..'});

% Loop over valid subdirectories
for iDir = find(validIndex)
    % Get the subdirectory path
    nextDir = fullfile(dir_name,subDirs{iDir});
    % Recursively call getAllFiles
    fileList = [fileList; swa_getFiles(nextDir, pattern)];
end

end