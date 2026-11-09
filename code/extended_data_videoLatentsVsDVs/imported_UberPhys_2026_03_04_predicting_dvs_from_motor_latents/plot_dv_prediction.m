%% plotting dv prediction from motor latents

path = fileparts(which(mfilename));
ext={'png','fig','pdf'};
 %load(fullfile(path,'dv_residual_predictions_offsets.mat'));

regions = DV.get_brain_regions;
Y=cell(numel(res),1);
Yhat=cell(numel(res),1);
Y_shuffle=cell(numel(res),1);
Yhat_shuffle=cell(numel(res),1);
time_s = res{1}(1).bin_params.time_s;
figure;hold on;
no = numel(offsets);
nt = numel(time_s);
nr=numel(regions);
for s=1:numel(res)
    ntrials{s} = numel(res{s}(1).Trials.gamma);
    Y{s} = NaN(ntrials{s},nr,nt,no);
    Yhat{s} = NaN(ntrials{s},nr,nt,no);    
    Y_shuffle{s} = NaN(ntrials{s},nr,nt);
    Yhat_shuffle{s} = NaN(ntrials{s},nr,nt);       
    for r=1:numel(regions)
        idx = [res{s}.region]==regions(r);
        if any(idx)
            %shuffle or regular fit
            fit = res{s}(idx).fit;
            shuffle_fit = res{s}(idx).shuffle_fit;            
            for o=1:no 
                for t=1:nt     
                    Y{s}(:,r,t,o)=fit(o,t).Y - nanmean(fit(o,t).Y);
                    Yhat{s}(:,r,t,o) = fit(o,t).Y_hat - nanmean(fit(o,t).Y_hat);
                    if o==1
                        Y_shuffle{s}(:,r,t)=shuffle_fit(t).Y - nanmean(shuffle_fit(t).Y);
                        Yhat_shuffle{s}(:,r,t) = shuffle_fit(t).Y_hat - nanmean(shuffle_fit(t).Y_hat);                    
                    end
                end
            end
        else
        end
    end
end



rsquarefun = @(x,y)rsquare(x,y,1,[-10 10]);
figure; 
clear R2 R2_offsets R2_all
gaussEqn = 'a*exp(-((x-b)/c)^2)+d';
for r=1:numel(regions)
        fun=@(x)reshape(squeeze(x(:,r,:,:)),[size(x,1)*nt no]);
        these_Y = cellfun(fun,Y,'uni',0);
        these_Y_hat = cellfun(fun,Yhat,'uni',0);
        for s=1:numel(res)
            nans = any(isnan(these_Y{s}),2) | any(isnan(these_Y_hat{s}),2);
            these_Y{s}=these_Y{s}(~nans,:);
            these_Y_hat{s}=these_Y_hat{s}(~nans,:);
        end
        boots_all{r} = hierarchical_bootstrp(300,rsquarefun,these_Y,these_Y_hat);    


        fun=@(x)reshape(squeeze(x(:,r,:)),[size(x,1) nt]);
        these_Y = cellfun(fun,Y_shuffle,'uni',0);
        these_Y_hat = cellfun(fun,Yhat_shuffle,'uni',0); 
        for s=1:numel(res)
            nans = any(isnan(these_Y{s}),2) | any(isnan(these_Y_hat{s}),2);
            these_Y{s}=these_Y{s}(~nans,:);
            these_Y_hat{s}=these_Y_hat{s}(~nans,:);
        end        
        boots_all_shuffle{r} = hierarchical_bootstrp(300,rsquarefun,these_Y,these_Y_hat);        

        for  o=1:no
            fun=@(x)reshape(squeeze(x(:,r,:,o)),[size(x,1)*nt 1]);
            these_Y = cellfun(fun,Y,'uni',0);
            these_Y_hat = cellfun(fun,Yhat,'uni',0); 
            these_Y = cat(1,these_Y{:});
            these_Y_hat = cat(1,these_Y_hat{:});
            R2_offsets(r,o) = rsquarefun(these_Y,these_Y_hat);
            for t=1:nt
                fun=@(x)reshape(squeeze(x(:,r,t,o)),[size(x,1) 1]);
                these_Y = cellfun(fun,Y,'uni',0);
                these_Y_hat = cellfun(fun,Yhat,'uni',0); 
                these_Y = cat(1,these_Y{:});
                these_Y_hat = cat(1,these_Y_hat{:});
                R2_all(r,o,t) = rsquarefun(these_Y,these_Y_hat);
            end
        end

        fun=@(x)reshape(squeeze(x(:,r,:,offsets==0)),[size(x,1) nt]);
        these_Y = cellfun(fun,Y,'uni',0);
        these_Y_hat = cellfun(fun,Yhat,'uni',0); 
        these_Y = cat(1,these_Y{:});
        these_Y_hat = cat(1,these_Y_hat{:});
        R2(r,:) = rsquarefun(these_Y,these_Y_hat);       

        [a,b] = max(boots_all{r}');
        sds(r) = std(offsets(b));
        hi(r)=prctile(offsets(b),75);
        lo(r)=prctile(offsets(b),25);
     


        mns(r)  = mean(offsets(b));



        errorbar(mns(r),r,0,0,sds(r),sds(r),'color',uberphys.get_brain_region_colors(regions(r)),'marker','.','markersize',30);hold on
drawnow;
end
set(gca,'YDir','reverse','ytick',1:numel(regions),'yticklabel',regions,'xlim',[-0.3 0.3],'ylim',[0 11]);
uberphys.color_tick_labels;        
xlabel('Best Time lag (video - spikes, s)');
ylabel('Brain region');

ext = {'pdf','fig','png'};
name='best lags';
for i=1:numel(ext)
   saveas(gcf,fullfile(path,[name,'.',ext{i}]));
end  

figure; clear h
for r=1:numel(regions)
    h(r)= plot(time_s,squeeze(R2(r,:)),'color',uberphys.get_brain_region_colors(regions(r)));hold  on;
end
z=cat(1,boots_all_shuffle{:});

patch([time_s flip(time_s)],[prctile(z,95),flip(prctile(z,5))],'k','FaceAlpha',0.5)

legend(h,regions);
xlabel('Time (s) after first click');
ylabel('DV prediction accuracy (R^2)');

  ext = {'pdf','fig','png'};
name='timecourse';
%% if using shuffle fits, this gives noise floor
for i=1:numel(ext)
   saveas(gcf,fullfile(path,[name,'.',ext{i}]));
end  

figure; clear h
for r=1:numel(regions)
    h(r)  = plot(offsets,R2_offsets(r,:),'color',uberphys.get_brain_region_colors(regions(r)));hold  on;
end
xlabel('Time lag (video - spikes, s)');
ylabel('DV residual prediction accuracy (R^2)');
set(gca,'xlim',[-0.3 0.3]);

ext = {'pdf','fig','png'};
name='lags';
%% if using shuffle fits, this gives noise floor
for i=1:numel(ext)
   saveas(gcf,fullfile(path,[name,'.',ext{i}]));
end      

function mx = get_max(x,y,xs)
    y2= interp1(x,y,xs);
    y2 = smooth(y2,25,'sgolay');
    
    [~,b] =  max(y2);
    mx = xs(b);
end