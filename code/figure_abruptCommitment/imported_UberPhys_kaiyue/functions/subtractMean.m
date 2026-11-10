function X_centered = subtractMean(X, group)

% subtract mean within each value in the group

% X: (ntrials, ntimes) or (ntrials, ntimes, ncells)
% group: (ntrials,1)

% X_centered: (ntrials, ntimes)

dim = length(size(X));

uniqueGroups = unique(group);
X_centered = zeros(size(X)); % Initialize centered matrix

if dim == 1
    for i = 1:length(uniqueGroups)
        idx = group == uniqueGroups(i);
        X_centered(idx) = X(idx) - mean(X(idx), 'omitnan'); % Subtract group mean
    end

elseif dim == 2
    for i = 1:length(uniqueGroups)
        idx = group == uniqueGroups(i);
        X_centered(idx,:) = X(idx,:) - mean(X(idx,:), 1, 'omitnan'); % Subtract group mean
    end

elseif dim == 3
    for i = 1:length(uniqueGroups)
        idx = group == uniqueGroups(i);
        X_centered(idx,:,:) = X(idx,:,:) - mean(X(idx,:,:), 1, 'omitnan'); % Subtract group mean
    end

else
    disp("Wrong Input Matrix");
end

end