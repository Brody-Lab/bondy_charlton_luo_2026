function idx = sort_items(items,order)
    [~,idx] = ismember(items,order);
    [~,idx] = sort(idx);
end