function corrs = select_times_from_corrs(corrs,time_s)
    assert(isscalar(corrs));
    assert(issorted(time_s));
    fields = fieldnames(corrs);
    timecourse_fields = fields(contains(fields,'timecourse'));
    lags_fields = fields(contains(fields,'lags'));
    lags_fields = lags_fields(lags_fields~="lags");
    xcorr_fields = fields(contains(fields,'xcorr'));    
    idx = ismember(corrs.time_s,time_s);
    lag_idx=ismember(corrs.lags,unique(round(time_s - time_s',6)));        
    if all(idx)
        return
    end
    for i=1:numel(timecourse_fields)
        if ndims(corrs.(timecourse_fields{i}))==2
            corrs.(timecourse_fields{i}) = corrs.(timecourse_fields{i})(:,idx);
            corrs.se.(timecourse_fields{i}) = corrs.se.(timecourse_fields{i})(:,idx);            
        else
            corrs.(timecourse_fields{i}) = corrs.(timecourse_fields{i})(:,:,idx);  
            corrs.se.(timecourse_fields{i}) = corrs.se.(timecourse_fields{i})(:,:,idx);                        
        end
    end
    for i=1:numel(lags_fields)
        corrs.(lags_fields{i}) = corrs.(lags_fields{i})(:,:,idx,idx);       
        corrs.se.(lags_fields{i}) = corrs.se.(lags_fields{i})(:,:,idx,idx);                    
    end   
    for i=1:numel(xcorr_fields)
        corrs.(xcorr_fields{i}) = corrs.(xcorr_fields{i})(:,:,:,lag_idx);
        corrs.se.(xcorr_fields{i}) = corrs.se.(xcorr_fields{i})(:,:,:,lag_idx);        
    end
    corrs.time_s = time_s;
    corrs.lags = corrs.lags(lag_idx);
end


