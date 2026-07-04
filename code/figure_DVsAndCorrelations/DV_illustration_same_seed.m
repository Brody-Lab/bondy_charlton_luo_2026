figure;
dvs=[];
count=0;
%res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',false);
%res=res{1}{1};
ntc=res(1).Trials.stateTimes.commitment_s-res(1).Trials.stateTimes.first_click;
i=4;a=find(res(1).Trials.seed == res(1).Trials.seed(i) & res(1).Trials.pokedR == res(1).Trials.pokedR(i));
for s=a([3 4 9 14])'
    count=count+1;
    for i=1:3
        dvs(:,i) = res(i).DV(s,:);
    end
    subplot(5,1,count+1);
    h=plot(res(1).bin_params.time_s,(dvs));
    for i=1:3
        h(i).Color = uberphys.get_brain_region_colors(res(i).region);    
    end
    set(gca,'ylim',[-0.6 0.6]);
    set(gca,'xlim',[0 0.8]);
    line(ones(1,2).*ntc(s),get(gca,'ylim'),'color',[0.8 0.5 0.3]);    
    if count==1
        ylabel('DV');xlabel('Time after first click (s)');legend([res(1:3).region]);
    end
    %title(sprintf('Seed Repeat %d',count));
end
subplot(5,1,1);
lb=res(1).Trials.leftBups{s};
for i=1:numel(lb)
    line([1 1]*lb(i),[-1 1],'color','b');
end
rb=res(1).Trials.rightBups{s};
for i=1:numel(rb)
    line([1 1]*rb(i),[-1 1]+3,'color','r');
end
set(gca,'ytick',[0 3],'yticklabel',{'left clicks','right clicks'});
set(gca,'xlim',[0 0.8]);




figure;
dvs=[];
count=0;
%res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',false);
%res=res{1}{1};
ntc=res(1).Trials.stateTimes.commitment_s-res(1).Trials.stateTimes.first_click;
i=8;a=find(res(1).Trials.seed == res(1).Trials.seed(i) & res(1).Trials.pokedR == res(1).Trials.pokedR(i));
for s=a(:)'
    count=count+1;
    for i=1:3
        dvs(:,i) = res(i).DV(s,:);
    end
    subplot(1,15,count);
    h=plot(res(1).bin_params.time_s,dvs);
    set(gca,'ylim',[-1 1]);
    line(ones(1,2).*ntc(s),get(gca,'ylim'));    
    if count==1
        ylabel('DV');xlabel('Time after first click (s)');legend([res(1:3).region]);
    end
    title(sprintf('Seed Repeat %d',count));
end