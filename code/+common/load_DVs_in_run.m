function res = load_DVs_in_run(dv_path,run,varargin)

    file_ending='_DVs.mat';
    if ~isfolder(fullfile(dv_path,run))
        error('Run %s is not found in the specified DV path: %s.',run,dv_path);
    end
    
    recording_id = deblank(string(ls(fullfile(dv_path,run))));
    recording_id = recording_id(contains(recording_id,file_ending));
    recording_id = regexprep(recording_id,['(.*)',file_ending],'$1');
    
    parfor i=1:numel(recording_id)
        this_file = fullfile(dv_path,run,strcat(recording_id(i),file_ending));
        fprintf('Loading %s.\n',this_file);
        tmp = load(this_file);  
        res{i} = tmp.res;
        failed=[];
        for k=1:length(res{i})
            if isfield(res{i}{k},'params')
                for n=1:length(res{i}{k})
                    if ~isfield(res{i}{k}(n).params,'recording_id')
                        res{i}{k}(n).params.recording_id = recording_id(i);
                    end
                end
                failed(k)=false;
            else
                failed(k)=true;
            end
        end
        if any(failed)
            res{i} = res{i}(~failed);
            warning('%d resamples failed for recording_id %s.',sum(failed),recording_id(i));
        end
    end
    if isfield(res,'corrs')
        res = rmfield(res,'corrs');
    end
end