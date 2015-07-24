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

if ischar(Data.Raw)
    fid = fopen(fullfile(filePath, Data.Raw));
    Data.Raw = fread(fid, Info.Recording.dataDim, 'single');
end

if isfield(Data, 'Filtered')
    if ischar(Data.Filtered)
        fid = fopen(fullfile(filePath, Data.Filtered));
        Data.Filtered = fread(fid, Info.Recording.dataDim, 'single');
    end
end

if ~exist('SW', 'var')
    SW = [];
end