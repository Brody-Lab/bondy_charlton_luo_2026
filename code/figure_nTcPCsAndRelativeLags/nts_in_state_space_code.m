% 
res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','variable','choice','by_hemisphere',true);
clear DVs DVs_corrected gidx
for i=1:numel(res)

    %% reformat res structs
    res{i} = res{i}{1};
     n_regions = numel(res{i});        
    res{i}(1).Trials = uberphys.add_Tc_to_Trials(res{i}(1).Trials);    
    for k=n_regions:-1:1
        res{i}(k).DV = res{i}(k).log_odds;
    end
    %res{i} = DV.equalize_trials(res{i},0.7); % only needed for legacy res

    [~,gidx{i},missing_trials] = DV.find_matched_trials(res{i}(1).Trials,{'seed','pokedR'}); 
    res{i} = DV.remove_trials_from_res(res{i},missing_trials);        
      
end
all_regions = DV.get_brain_regions;
nsamps=2;

clear explained explained_null
for k=5
sess=k;
clear ntcs
regions=unique([res{sess}.region]);
for r=numel(regions):-1:1

    ntcs(:,r)=res{sess}(1).Trials.stateTimes.(sprintf("committime_s_%s",regions(r))) - res{sess}(1).Trials.stateTimes.first_click;
end
ngroup = max(gidx{sess});

ntcs = DV.subtract_group_mean(ntcs,gidx{sess},'exclude_self',true);


end

labels=unique([res{sess}.region]);
figure;
regions=[1 4 8];
for i=1:size(X,2)
    zrs = X(:,i) == nanmedian(ntcs(:,i));
    X(zrs,i)=NaN;
end
sz=100;
lim=0.4;
resolution=1;
range=-lim:resolution:lim;
o=ones(size(X,1),1);
h=scatter3(X(1:end,regions(1)),X(1:end,regions(2)),X(1:end,regions(3)),'MarkerFaceColor','k','MarkerEdgeColor','none','MarkerFaceAlpha',0.5,'SizeData',sz);
set(gca,'ylim',lim*[-1 1],'xlim',lim*[-1 1],'zlim',lim*[-1 1]);
%h=scatter3(-lim*o,X(1:end,regions(2)),X(1:end,regions(3)),'MarkerFaceColor',[0.9 0.9 0.9]*0,'MarkerEdgeColor','none','MarkerFaceAlpha',0.07,'SizeData',sz);
%h=scatter3(X(1:end,regions(1)),lim*o,X(1:end,regions(3),'MarkerFaceColor',[0.9 0.9 0.9]*0,'MarkerEdgeColor','none','MarkerFaceAlpha',0.07,'SizeData',sz);
%h=scatter3(X(1:end,regions(1)),X(1:end,regions(2)),-lim*o,'MarkerFaceColor',[0.9 0.9 0.9]*0,'MarkerEdgeColor','none','MarkerFaceAlpha',0.07,'SizeData',sz);

set(gca,'ylim',lim*[-1 1],'xlim',lim*[-1 1],'zlim',lim*[-1 1],'CameraPosition',[56 -56 34]);
grid on
xlabel(sprintf('nTc using %s',labels(regions(1))));
ylabel(sprintf('nTc using %s',labels(regions(2))));
zlabel(sprintf('nTc using %s',labels(regions(3))));
