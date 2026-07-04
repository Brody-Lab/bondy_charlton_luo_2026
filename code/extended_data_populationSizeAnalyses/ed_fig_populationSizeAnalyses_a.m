% jukebox_path='D:';
% sessions=uberphys.load_bcl_sessions_table;
% regions=DV.get_brain_regions;
% hemispheres=["left" "right"];
% for s=1:height(sessions)
%     fprintf('Loading Cells files for %s\n',sessions.recording_id(s));
%     Cells = uberphys.load_Cells_files(sessions.recording_id(s),'jukebox_path',jukebox_path);
%     Cells.region = uberphys.simplify_region_names(Cells.region);
%     include = uberphys.apply_inclusion_criteria(Cells);
%     for r=1:numel(regions)
%         for h=1:2
%             n_units(s,r,h) = sum(Cells.region==regions(r) & Cells.hemisphere(Cells.probe_idx)==hemispheres(h) & include);
%         end
%     end
% end

figure('position',[1000         763        1091         476]);
for i=1:2
subplot(1,2,i);
h=imagesc(reordercats(categorical(regions),regions),categorical(string(extract_sessiondate_from_path(sessions.recording_id))),log10(squeeze(n_units(:,:,i))));
colormap(parula);
set(gca,'clim',log10([1 500]));
set(h,'AlphaData',squeeze(n_units(:,:,i))>0);
colorbar;
box off;
uberphys.color_tick_labels;
end


ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
for i=1:numel(ext)
    saveas(gcf,fullfile(path,[mfilename,'.',ext{i}]));
end
