    regions = [ "MGB" "M1" "dmFC" "ADS" "mPFC" "TS" "S1"    "NAc" "BLA" "HPC" ];
  

% res_click = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','variable','choice','by_hemisphere',false,'frozen',false,'causal',false);
% for r=1:numel(regions)
%   tmp = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event',['committime_s_without_',char(regions(r))],'variable','choice','by_hemisphere',false,'frozen',false,'causal',false);
%   for k=1:numel(tmp)
%       these_regions=[tmp{k}{1}.region];      
%       idx=these_regions==regions(r);
%       if any(idx)
%         res_commit{k}{1}(r) = tmp{k}{1}(idx);
%         res_commit{k}{1}(r).Trials = tmp{k}{1}(1).Trials;
%       end
%   end
% end
% 
%  for k=1:numel(res_commit)
%      empty=false(numel(res_commit{k}{1}),1);
%     for r=1:numel(res_commit{k}{1})
%         if isempty(res_commit{k}{1}(r).Y)
%             empty(r)=true;
%         end
%     end
%     res_commit{k}{1} = res_commit{k}{1}(~empty);
%  end
% 
% 
%   res_cpoke_out = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','cpoke_out','variable','choice','by_hemisphere',false,'frozen',false,'causal',false);
% 

all_res_click=res_click;
all_res_commit=res_commit;
all_res_cpoke_out=res_cpoke_out;

rat="A327";

 ext={'pdf','png','fig'};
 path=fileparts(which(mfilename));

xlim = {[0 0.8],[-0.4 0.4],[-0.8 0]};
xlim_plot = {[0 0.8],[-0.4 0.4],[-0.8 0]};
xtick = {[0 0.4 0.8],[-0.4 0 0.4],[-0.8 -0.4 0]};
thresh=10;
ylim={[0 4],[0 4],[0 4]};hold on;
nresamples=100;
a=figure('position',[  450         203        1440         453]);
b=figure('position',[   139   858   542   258]);
c=figure('position',[  450         203        1440         453]);
e=figure('position',[  450         203        1440         453]);
for d=1:3
    switch d
        case 1
            res=res_click;
        case 2
            res = res_commit;
        case 3
            res = res_cpoke_out;
    end

    clear choice
    DVs = cell(numel(regions),1);
    DVs_by_sess = cell(numel(regions),1);    
    clear bad
    for i=numel(res):-1:1
        if res{i}{1}(1).params.recording_id=="C211_2024_01_01" || res{i}{1}(1).params.recording_id=="C211_2024_01_02"
            bad(i)=true;
        else
            bad(i)=false;
        end
    end
    res=res(~bad);
    clear bad
    for i=numel(res):-1:1    
        %% reformat res structs
        if iscell(res{i})
            res{i} = res{i}{1};
        end
         n_regions = numel(res{i});        
        for k=n_regions:-1:1
            res{i}(k).DV = double(res{i}(k).eta_same_lambda);
        end
        
        if d~=2
        missing_trials = isnan(res{i}(1).Trials.stateTimes.committime_s_all);
        res{i} = DV.remove_trials_from_res(res{i},missing_trials);        
        end
        for k=1:numel(regions)
            if i==numel(res)
                DVs_by_sess{k} = cell(numel(res),1);
            end
            idx = ismember([res{i}.region],regions(k));
            if any(idx)
                if d==2
                    choice = res{i}(idx).Trials.pokedR;                
                else
                    choice = res{i}(1).Trials.pokedR;                
                end
                these_dvs=[res{i}(idx).DV(choice==1,:);-res{i}(idx).DV(choice==0,:)];
                DVs{k} = [DVs{k};these_dvs];       
                DVs_by_sess{k}{i} = these_dvs;
            end
        end        
    end
    %figure(a);
    x=res{1}(1).bin_params.time_s;
    %subplot(1,3,d);
    clear data
    for i=numel(regions):-1:1
        bad = any(abs(DVs{i})>thresh,2); % remove outliers which bias the mean
        data{i} = nanmean(DVs{i}(~bad,:));            
        %plot(x,data{i},'linewidth',2,'color',uberphys.get_brain_region_colors(regions(i)));hold on;
    end
   % ylabel('signed average DV across choices');
   % set(gca,'xlim',xlim_plot{d},'ylim',ylim{d},'xtick',xtick{d});    
    switch d
        case 1
            xlabel('Time (s) relative to first click');            
        case 2
            xlabel('Time (s) relative to nTc-M1');            
        case 3
            xlabel('Time (s) relative to movement onset');
    end






    figure(c);
    subplot(1,3,d);
    for i=numel(regions):-1:1
        x_new = xlim_plot{d}(1):0.01:xlim_plot{d}(2);
        idx = x>=xlim{d}(1) & x<=xlim{d}(2);
        pred_lin = segmented_regression(x(idx),data{i}(idx),1,true);  
        [pred,~,fit_fun] = segmented_regression(x(idx),data{i}(idx),2,true);                
        errs{i}=pred-data{i}(idx);
        errs_lin{i} = pred_lin - data{i}(idx);
        y_fit{i} = fit_fun(x_new);
        plot(x_new,y_fit{i},'linewidth',2,'color',uberphys.get_brain_region_colors(regions(i)));hold on;
    end
    if d==2
        ntc_errs=errs;
        ntc_errs_lin=errs_lin;
    end
    ylabel('signed average DV across choices');
    set(gca,'xlim',xlim_plot{d},'ylim',ylim{d},'xtick',xtick{d});    
    switch d
        case 1
            xlabel('Time (s) relative to first click');            
        case 2
            xlabel('Time (s) relative to nTc-loo');            
        case 3
            xlabel('Time (s) relative to movement onset');
    end    




    clear data
    for i=1:numel(regions)
        
        bad = any(abs(DVs{i})>thresh,2); % remove outliers which bias the mean
        data{i} = bootstrp(nresamples,@nanmean,DVs{i}(~bad,:));           
        for k=1:numel(res)
            bad = any(abs(DVs_by_sess{i}{k})>thresh,2);
            DVs_by_sess{i}{k} = DVs_by_sess{i}{k}(~bad,:);
        end
        nonempty = ~cellfun(@isempty,DVs_by_sess{i});
        data_by_sess{i} = hierarchical_bootstrp(nresamples,@nanmean,DVs_by_sess{i}(nonempty),false); 
    end



    clear params y_fit
    for i=numel(regions):-1:1
        idx = x>=xlim{d}(1) & x<=xlim{d}(2);
        this_data=data_by_sess{i}(:,idx);        
        clear y p
        parfor s=1:nresamples
            [y(s,:),p(s,:)] = segmented_regression(x(idx),this_data(s,:),2);
        end
        y_fit{i}=y;
        params{i}=p;
    end    
    if d==2
        ntc_params = params;
    end

    figure(a);
    x=res{1}(1).bin_params.time_s;
    subplot(1,3,d);
    for i=numel(regions):-1:1
        shadedErrorBar(x,data{i},{@nanmean,@nanstd},{'linewidth',2,'color',uberphys.get_brain_region_colors(regions(i))});hold on;
    end
    ylabel('signed average DV across choices');
    set(gca,'xlim',xlim_plot{d},'ylim',ylim{d},'xtick',xtick{d});    
    switch d
        case 1
            xlabel('Time (s) relative to first click');            
        case 2
            xlabel('Time (s) relative to nTc-loo');            
        case 3
            xlabel('Time (s) relative to movement onset');
    end
    

    figure(e);
    subplot(1,3,d);
    mn_break_pt = cellfun(@(x)mean(x(:,1)),params);
    %[~,sort_idx] = sort(mn_break_pt);
    sd_break_pt = cellfun(@(x)std(x(:,1)),params);    
    for i=1:numel(regions)
        line([1 1]*mn_break_pt(i),[-0.3 0.3]+i,'color',uberphys.get_brain_region_colors(regions(i)),'LineWidth',2);hold on
        patch([-1 1 1 -1]*sd_break_pt(i)+mn_break_pt(i),[-0.3 -0.3 0.3 0.3]+i,uberphys.get_brain_region_colors(regions(i)),'facealpha',0.3,'edgecolor','none');
    end
    %errorbar(mn_break_pt,1:numel(regions),0,0,sd_break_pt,sd_break_pt,'color','k'); 
    set(gca,'ytick',1:numel(regions),'yticklabels',regions,'XLim',xlim{d},'ydir','reverse');
    uberphys.color_tick_labels;     
    ylabel('Breakpoint');
    switch d
        case 1
            xlabel('Time (s) relative to first click');            
        case 2
            xlabel('Time (s) relative to nTc-loo');            
        case 3
            xlabel('Time (s) relative to movement onset');
    end   
    figure(b);
    subplot(1,3,d);
    for i=numel(regions):-1:1
        errorbar([1 2],mean(params{i}(:,[2 3])),std(params{i}(:,[2 3])),'color',uberphys.get_brain_region_colors(regions(i)));hold on
        plot([1 2],mean(params{i}(:,[2 3])),'marker','.','color',uberphys.get_brain_region_colors(regions(i)),'markersize',30);hold on        
        set(gca,'xlim',[0.5 2.5]);
    end
    matchylim(gcf);
    ylabel('slope');
    line([0.5 2.5],[0 0],'linestyle',':','color','k');
    set(gca,'xtick',[1 2],'xticklabel',{'segment 1','segment 2'});
    switch d
        case 1
            xlabel('Time (s) relative to first click');            
        case 2
            xlabel('Time (s) relative to nTc-loo');            
        case 3
            xlabel('Time (s) relative to movement onset');
    end    




    % figure(c);
    % subplot(1,3,d);
    % clear data
    % for i=numel(regions):-1:1
    %     x_new = xlim{d}(1):0.01:xlim{d}(2);
    %     y_fit_mn = mean(y_fit{i});
    %     y_fit_sd = std(y_fit{i});
    %     shadedErrorBar(x(idx),y_fit_mn,y_fit_sd,{'linewidth',2,'color',uberphys.get_brain_region_colors(regions(i))});
    % end
    % ylabel('signed average DV across choices');
    % set(gca,'xlim',xlim{d});    
    % switch d
    %     case 1
    %         xlabel('Time (s) relative to first click');            
    %     case 2
    %         xlabel('Time (s) relative to nTc-M1');            
    %     case 3
    %         xlabel('Time (s) relative to movement onset');
    % end    



end

figure(a);
set(gcf,'renderer','painters')
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['mean_dvs_diff_alignment.',ext{i}]));
end

figure(c);
set(gcf,'renderer','painters')
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['mean_dvs_diff_alignment_fit.',ext{i}]));
end

figure(b);
set(gcf,'renderer','painters')
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['slopes_by_region.',ext{i}]));
end

figure(e);
set(gcf,'renderer','painters')
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['breakpoints_by_region.',ext{i}]));
end