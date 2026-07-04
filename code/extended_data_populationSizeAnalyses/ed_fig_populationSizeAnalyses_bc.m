% res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'frozen',false);
% for i=1:numel(res)
%     res{i}=res{i}{1};
% end
%res=[res{:}];
m=cat(1,res.metrics);
accuracy=mean(arrayfun(@(x)x.balanced_accuracy,m),2);
nu = [res.n_units];
regions=[res.region];
unique_regions=unique(regions);
figure('position',[1000         862         894         376]);
for i=1:numel(unique_regions)
    idx=regions==unique_regions(i);
    subplot(1,2,1);
    h(i)=scatter(nu(idx),accuracy(idx),'o','SizeData',100,'MarkerFaceAlpha',0.8,'MarkerFaceColor',uberphys.get_brain_region_colors(unique_regions(i)),'MarkerEdgeColor','none');hold on;
    subplot(1,2,2);
    nu_corrected(idx,1) = (nu(idx) - mean(nu(idx)));
    accuracy_corrected(idx,1) = accuracy(idx) - mean(accuracy(idx));
    h(i)=scatter(nu_corrected(idx),accuracy_corrected(idx),'o','SizeData',100,'MarkerFaceAlpha',0.8,'MarkerFaceColor',uberphys.get_brain_region_colors(unique_regions(i)),'MarkerEdgeColor','none');hold on;    
end
g(1)=neuro_glmnet(log(nu'),accuracy);
p(1)= empirical_p(0,bootstrp(1000,@rsquare,g(1).Y,g(1).Y_hat),'both');
g(2)=neuro_glmnet(nu_corrected,accuracy_corrected);
p(2)= empirical_p(0,bootstrp(1000,@rsquare,g(2).Y,g(2).Y_hat),'both');
subplot(1,2,1);
%legend(h,unique_regions);
text(20,0.86,sprintf('R^2=%g\np=%g',round(g(1).metrics.R2,2),round(p(1),2)),'FontSize',12,'HorizontalAlignment','center');
set(gca,'xscale','log');
xlabel('No. units');
ylabel('Choice Prediction Accuracy');
subplot(1,2,2);
%legend(h,unique_regions);
set(gca,'xscale','linear');
text(0.28,0.115,sprintf('R^2=%g\np=%g',round(g(2).metrics.R2,2),round(p(2),2)),'FontSize',12,'HorizontalAlignment','center');
xlabel({'No. units','(normalized by region)'});
ylabel({'Choice Prediction Accuracy','(normalized by region)'});

ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
for i=1:numel(ext)
    saveas(gcf,fullfile(path,[mfilename,'.',ext{i}]));
end



