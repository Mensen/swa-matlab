function [Data, Info] = swa_changeReference(Data, Info, new_reference)

if nargin < 3
    new_reference = [94, 190];
end

% calculate the average mastoid activity
reference_data = mean(Data.Raw(new_reference, :), 1); 

% rereference the data
Data.Raw = Data.Raw - repmat(reference_data, [size(Data.Raw, 1), 1]);

% remove the mastoid channels for the data set
Data.Raw(new_reference, :) = [];

% update the info structure
Info.Electrodes(new_reference) = [];
Info.Recording.dataDim(1) = size(Data.Raw, 1);
Info.Recording.new_reference = new_reference;