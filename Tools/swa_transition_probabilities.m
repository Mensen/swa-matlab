function [sleep_tpm, stage_count] = swa_transition_probabilities(stages)
% swa_transition_probabilities
% TODO: ignore stage 4 (artefact)

% pre-allocate tpms
stage_count = nan(6);
sleep_tpm = nan(6);

% loop for each starting stage
for n = 1 : 6
    
    % find the start points
    stage_starts = find(diff([1, stages == n - 1]) == 1) - 1;

    % find the end of stage points
    stage_ends = find(diff([0, stages == n - 1]) == -1) - 1;
    
    % which stages come next
    next_stages = stages(stage_ends + 1);

    for m = 1 : 6
        
        % count the times current stage transitions into each other one
        stage_count(n, m) = sum (next_stages == m - 1);
        
        if n == m
            stage_count(n, m) = length(next_stages);
        end
    
        % convert to probabilities
        sleep_tpm(n, m) = stage_count(n, m) / length(next_stages);

    end
end

% make diagonal elements zero
idx = logical(eye(size(sleep_tpm)));
sleep_tpm(idx) = 0;
