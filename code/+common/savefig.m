function savefig(gcf,mfilename)
    %mfilename should be full
    ext={'pdf','png','fig'}; % set of file types to save out
    if ~isempty(which(mfilename))
        mfilename=which(mfilename);
    end
    [path,name]=fileparts(mfilename);
    path = strrep(path,'code','plots');
    for i=1:numel(ext)
        fig_path=fullfile(path,[char(name),'.',ext{i}]);            
        if ext{i}=="fig"
            savefig(gcf,fig_path,'compact');
        else
            exportgraphics(gcf,fig_path,'ContentType','vector','resolution',400);
        end
    end
end