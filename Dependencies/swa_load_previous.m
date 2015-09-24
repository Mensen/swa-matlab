function [Data, Info, SW] = swa_load_previous(fileName, filePath)

% check arguments
if nargin < 1;
    [fileName, filePath] = uigetfile('*.mat');
elseif nargin < 2
    % attempt to get fileparts
    [filePath, fileName, ext] = fileparts(fileName);
    fileName = [fileName, ext];
end

% load the file (only data pointer)
load(fullfile(filePath, fileName), '-mat');

% check for correct file
if ~exist('Info', 'var')
    error('No Info struct found in mat file');
end

% if the Data is a pointer than read the binary file
if ischar(Data.Raw)
    fid = fopen(fullfile(filePath, Data.Raw));
    Data.Raw = fread(fid, Info.Recording.dataDim, 'single');
end

% check for a filtered version
if isfield(Data, 'Filtered')
    if ischar(Data.Filtered)
        fid = fopen(fullfile(filePath, Data.Filtered));
        Data.Filtered = fread(fid, Info.Recording.dataDim, 'single');
    end
end

% check for the wave struct existence
if ~exist('SW', 'var') && ~exist('SS', 'var') && ~exist('ST', 'var')
    SW = [];
    return
end

% change wavetype of SS/ST if it exists
if exist('SS', 'var')
    SW = SS;
elseif exist('ST', 'var')
    SW = ST;
end