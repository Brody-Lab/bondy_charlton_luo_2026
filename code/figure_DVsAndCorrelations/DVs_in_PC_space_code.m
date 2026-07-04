figure;
regions=[1 3 5];
for i=1:size(X,2)
    zrs = X(:,i) == nanmedian(X(:,i));
    X(zrs,i)=NaN;
end
lim=5;
resolution=1;
range=-lim:resolution:lim;
o=ones(size(X,1),1);
h=scatter3(X(1:end,regions(1)),X(1:end,regions(2)),X(1:end,regions(3)),'MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',0.3,'SizeData',70);
set(gca,'ylim',lim*[-1 1],'xlim',lim*[-1 1],'zlim',lim*[-1 1]);
h=scatter3(-5*o,X(1:end,regions(2)),X(1:end,regions(3)),'MarkerFaceColor',[0.9 0.9 0.9]*0,'MarkerEdgeColor','none','MarkerFaceAlpha',0.05,'SizeData',70);
h=scatter3(X(1:end,regions(1)),5*o,X(1:end,regions(3)),'MarkerFaceColor',[0.9 0.9 0.9]*0,'MarkerEdgeColor','none','MarkerFaceAlpha',0.05,'SizeData',70);
h=scatter3(X(1:end,regions(1)),X(1:end,regions(2)),-5*o,'MarkerFaceColor',[0.9 0.9 0.9]*0,'MarkerEdgeColor','none','MarkerFaceAlpha',0.05,'SizeData',70);

% 
% 
% [x,Y,Z] = meshgrid(range,range,range);
% counts = histcounts2(X(1:end,4),X(1:end,5),range,range); 
% x=x(1:end-1,1:end-1,1:end-1)+resolution/2;
% Y=Y(1:end-1,1:end-1,1:end-1)+resolution/2;
% Z=Z(1:end-1,1:end-1,1:end-1)+resolution/2;
% V=zeros(size(x));
% V(:,1,:)= counts;
% h=contourslice(x, Y, Z, log(5+V), range(1)+resolution/2,[], [],10)
% 
% 
% 
% [x,Y,Z] = meshgrid(range,range,range);
% counts = histcounts2(X(1:end,1),X(1:end,4),range,range); 
% x=x(1:end-1,1:end-1,1:end-1)+resolution/2;
% Y=Y(1:end-1,1:end-1,1:end-1)+resolution/2;
% Z=Z(1:end-1,1:end-1,1:end-1)+resolution/2;
% V=zeros(size(x));
% V(:,:,1)= counts;
% h=contourslice(x, Y, Z, log(5+V), [],[], range(1)+resolution/2,10)
% 


set(gca,'ylim',lim*[-1 1],'xlim',lim*[-1 1],'zlim',lim*[-1 1],'CameraPosition',[56 -56 34]);
grid on
xlabel(sprintf('%s %s DVs',new_hemi(regions(1)),new_regions(regions(1))));
ylabel(sprintf('%s %s DVs',new_hemi(regions(2)),new_regions(regions(2))));
zlabel(sprintf('%s %s DVs',new_hemi(regions(3)),new_regions(regions(3))));
hold on;
h=line([0 vec(1)]*5,[0 vec(2)]*5,[0 vec(3)]*5);