% % 
 % res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','variable','choice','by_hemisphere',true,'frozen',false);
 % sessions=uberphys.load_bcl_sessions_table;
 % res=res(logical(sessions.frozen));

nsamps=5;

clear explained explained_null explained_sim_1 explained_sim_2
parfor k=1:numel(res)

    [explained{k},explained_sim_1{k},explained_sim_2{k},explained_null{k}] = main_loop(res{k},nsamps);
end

fig_path = which(mfilename);
figure;scatter3(ntcs(:,1),ntcs(:,4),ntcs(:,8));
 explained{4}(8,:)=NaN;
explained{5}(8,:)=NaN;
explained{6}(8,:)=NaN;
explained_null{4}(8,:)=NaN;
explained_null{5}(8,:)=NaN;
explained_null{6}(8,:)=NaN;
explained_sim_1{4}(8,:)=NaN;
explained_sim_1{5}(8,:)=NaN;
explained_sim_1{6}(8,:)=NaN;
explained_sim_2{4}(8,:)=NaN;
explained_sim_2{5}(8,:)=NaN;
explained_sim_2{6}(8,:)=NaN;
figure('position',[143   950   448   313]);
h(1)=plot_pca_spectrum(explained,8,[ 0 0 0]);hold on;
h(2)=plot_pca_spectrum(explained_sim_1,8,[1 0 0]);
h(3)=plot_pca_spectrum(explained_sim_2,8,[0 1 0]);
h(4)=plot_pca_spectrum(explained_null,8,[1 1 1]/2);
legend(h,{'data','1 shared','2 shared','independent'});



set(gca,'xlim',[0.5 8]);
common.savefig(gcf,fig_path);



function [explained,explained_sim_1,explained_sim_2,explained_null] = main_loop(res,nsamps)


 if iscell(res)
     res=res{1};
 end

  [~,gidx,missing_trials] = DV.find_matched_trials(res(1).Trials,{'seed','pokedR'}); 
     res = DV.remove_trials_from_res(res,missing_trials);          

    regions=unique([res.region]);
    for r=numel(regions):-1:1
    
        ntcs(:,r)=res(1).Trials.stateTimes.(sprintf("committime_s_%s",regions(r))) - res(1).Trials.stateTimes.first_click;
    end
    loadings = myppca(ntcs,5);
    loadings=loadings(:,1);
    for samp=1:nsamps
        sim1=randi(2);
        if sim1==1
            sim2=2;
        elseif sim1==2
            sim2 = 1;
        end
        loadings_noise = loadings+rand(size(loadings))*0.01;
        [~,idx]=sort(loadings_noise);
        idx1=idx(1:2:end);
        for r=numel(regions):-1:1
            ntcs_sim_1{samp}(:,r)=res(1).Trials.stateTimes.(sprintf("simulated_committime_s_%s_%d",regions(r),sim1)) - res(1).Trials.stateTimes.first_click;                
            if ismember(r,idx1)
                ntcs_sim_2{samp}(:,r)=res(1).Trials.stateTimes.(sprintf("simulated_committime_s_%s_%d",regions(r),sim1)) - res(1).Trials.stateTimes.first_click;    
            else
                ntcs_sim_2{samp}(:,r)=res(1).Trials.stateTimes.(sprintf("simulated_committime_s_%s_%d",regions(r),sim2)) - res(1).Trials.stateTimes.first_click;    
            end
        end
    end
    

    ntcs = DV.subtract_group_mean(ntcs,gidx,'exclude_self',false);
    good=sum(~isnan(ntcs)')>0;
    ntcs=ntcs(good,:);
    
    for samp=1:nsamps
        ntcs_sim_1{samp} = DV.subtract_group_mean(ntcs_sim_1{samp},gidx);
        good=sum(~isnan(ntcs_sim_1{samp})')>0;
        ntcs_sim_1{samp}=ntcs_sim_1{samp}(good,:);    
    
        ntcs_sim_2{samp} = DV.subtract_group_mean(ntcs_sim_2{samp},gidx);
        good=sum(~isnan(ntcs_sim_2{samp})')>0;
        ntcs_sim_2{samp}=ntcs_sim_2{samp}(good,:);       
    end
    
    
    [n,n2]=size(ntcs);
    clear exp expn exp_sim_1 exp_sim_2
    %[coeff{k},~,exp(:,nsamps)] = myppca(ntcs,n2-1);
    count=0;
    samp=1;
    rank=n2-1;
    while samp<(nsamps+1)
        try
            idx=randsample(n,n,true);
            ntc_perm=ntcs;
            idx = randperm(n);    
            for r=1:numel(regions)
                ntc_perm(:,r) = ntc_perm(circshift(idx(:),r,1),r);
            end
            good=sum(~isnan(ntc_perm)')>0;            
            [~,~,expn(:,samp)] = myppca(ntc_perm(good,:),rank);       
            [~,~,exp(:,samp)] = myppca(ntcs(idx,:),rank);        
            [~,~,exp_sim_1(:,samp)] = myppca(ntcs_sim_1{samp},rank);   
            [~,~,exp_sim_2(:,samp)] = myppca(ntcs_sim_2{samp},rank);                    
            samp=samp+1;
        catch ME
            clear  exp expn exp_sim_1 exp_sim_2
            samp=1;
            count=count+1;
            if count>=2
                warning('got stuck in rank reduction at least  2 times for %s.',res(1).Trials.sess_date{1});
            end
            rank=rank-1;
            if rank<2
                rethrow(ME);
            end
        end
    end
    explained = exp ./ sum(exp);
    explained_null = expn./ sum(expn);
    explained_sim_1 = exp_sim_1./ sum(exp_sim_1);
    explained_sim_2 = exp_sim_2./ sum(exp_sim_2);  
end

function [a,b,c] = myppca(ntcs,rank)

z=nanstd(ntcs);
ntcs=ntcs./z;

[a,b,c] = ppca(ntcs,rank);

end

function h=plot_pca_spectrum(explained,max_pcs,color)

    % explained should be a cell array of length nsess
    
    % each element should be npcs X nresamps matrix
    
    if nargin<3
        color=[0 0 0];
    end
    
    nsess=numel(explained);
    for i=1:nsess
        explained{i} = explained{i}(1:max_pcs,:)';
    end
    
    boots=hierarchical_bootstrp(1000,@nanmean,explained,true);    
    
    h = errorbar(1:max_pcs,nanmean(boots),nanstd(boots),'color',color);
    
    h.CapSize=eps;
    %h.LineStyle='none';
    h.Marker='.';
    h.MarkerSize=20;
    h.LineWidth=2;
    set(gca,'xlim',[1 max_pcs]);
    ylabel('Fraction Variance Explained');
    xlabel('Number of PCs');
    
    set(gca,'xgrid','on','xtick',[1 2 5 10],'xlim',[0.5 10])

end