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
sess=5;
seed=33;
Trials = res{sess}(1).Trials;
clear ntcs
regions=unique([res{sess}.region]);
for r=1:numel(regions)

    ntcs(:,r)=Trials.stateTimes.(sprintf("committime_s_%s",regions(r))) - Trials.stateTimes.first_click;
end



trials = find(gidx{sess}==seed);
lbups = Trials.leftBups{trials(1)};
rbups = Trials.rightBups{trials(1)};
lbups = lbups-lbups(1);
rbups = rbups-rbups(1);


figure;
r=["M1" "ADS" "dmFC" "mPFC" "TS" "HPC" "S1" "BLA" "NAc"];
[i,j] = find(regions'==r);
regions=regions(i);
ntcs= ntcs(:,i);
colors = uberphys.get_brain_region_colors(regions);
nr=numel(regions);

idx=[4  8 10 14 15 17 18]

for k=1:numel(idx)
    subplot(numel(idx)+1,1,k+1);
    x=ntcs(trials(idx(k)),:);
    y=[0 ;1];
    for n=1:nr
        line(repmat(x(n),2,1),y+n-1,'linewidth',2,'color',colors(n,:));
    end
set(gca,'xlim',[0 0.7]);
set(gca,'ylim',[0 nr+1],'ydir','reverse','tickdir','out','ytick',[]);
end

subplot(numel(idx)+1,1,1);
line(repmat(lbups,2,1),[0; 1],'linewidth',2,'color','b');
line(repmat(rbups,2,1),[1; 2],'linewidth',2,'color','r');


%30, 53, 70, 77, 78, 93, 94 sess 4

% 3,4,8,10,12,14,19,24,26,30,31,33 session 5
