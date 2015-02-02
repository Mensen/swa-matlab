function swa_topographyStatistics(data_files)
% analysing slow wave topographies using EEG Permutation Testing

if nargin < 1
    % plan the data structure
    data_files = {  'swaBatch_Defaults.mat', 'swaBatch_er_am.mat';
        'swaBatch_rm_2.mat',     'swaBatch_er2_rm2.mat'};
end

% loop for each dataset
data = cell(2,2);
for o = 1:numel(data_files)
    % load the specific dataset
    load(data_files{o});
    
    % get the topographic data (normalised by wave density)
    topo_data = zeros(length(output), length(output(1).topo_density));
    for n = 1:length(output)
        topo_data(n, :) = output(n).topo_density / nSW{o}(n);
    end
    
    % if comparing different references make sure electrodes are the same
    % TODO: generalise this for non-rereferenced comparisons
    if size(output(1).topo_density, 2) > 255
        topo_data(:, [94, 190]) = [];
    end
    
    % repeat the time point at least once to avoid TFCE errors
    data{o} = repmat(topo_data, [1, 1, 2]);
    
end

% run the TFCE analysis
ept_TFCE_ANOVA(data, Info.Electrodes);