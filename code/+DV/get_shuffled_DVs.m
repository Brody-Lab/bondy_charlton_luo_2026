function DVs_shuffled = get_shuffled_DVs(DVs,match_idx)
    nresamples=size(match_idx,2);
    for i=nresamples:-1:1
        DVs_shuffled{i} = DVs(match_idx(:,i),:);
    end
end