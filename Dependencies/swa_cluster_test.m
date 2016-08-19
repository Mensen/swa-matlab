function [clusters] = swa_cluster_test(data, ChN, threshold)

% data = randi([1, 10], [256, 1]);

% test data and near neighbours
% data = [1, 6, 7, 6, 3, 3, 4, 5, 4, 1]
% ChN = [1:10; [1:10] + 1]'; ChN(10, 2) = 1;


% pre-allocate output
flag_used = false(size(data));
clusters = nan(size(data));

% start the id
cluster_id = 1;
for n = 1 : size(data, 1)
       
    if ~flag_used(n) & data(n) > threshold
    
        % mark the channel as examined
        flag_used(n) = true;
        % start a new count and cluster list of channels
        current_count = 1;
        cluster_list = n;
        
        % loop will stop when all channels in the cluster list have been checked
        while current_count <= length(cluster_list)
            
            % which channel are we looking at now
            current_channel = cluster_list(current_count);
            
            % list of neighbours of the channel currently looked at
            current_neighbours = nonzeros( ChN( current_channel, : ))';            
            
            % find which channels would be in the cluster (and not already found)
            in_cluster = data(current_neighbours) > threshold & ~flag_used(current_neighbours);
            
            if sum(in_cluster) > 0
                % mark those channels as examined
                flag_used(current_neighbours(in_cluster)) = true;
            
                % expand the list of channels to look at
                cluster_list = [cluster_list, current_neighbours(in_cluster)]; %#ok<AGROW>
            end

            % go to next channel in the list
            current_count = current_count + 1;
            
        end
        
        % in the output just put the cluster_id on all channels in that cluster
        clusters(cluster_list) = cluster_id;
        % add to the cluster counter
        cluster_id = cluster_id + 1;
        
    end
    
end