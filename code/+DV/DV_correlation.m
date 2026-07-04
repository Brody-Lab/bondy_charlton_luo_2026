function corrs = DV_correlation_new(DVs,time_s,varargin)

    % a reduced version of the older code that does no preprocessing of the
    % "res" structures that are output by the DV estimation. It just takes
    % the already pre-processed DVs as inputs and returns a corrs
    % structure.

    %% validate DVs
    ntrials=unique(cellfun(@(x)size(x,1),DVs));
    if numel(ntrials)>1
        error('All DVs must have identical numbers of trials.');
    end
    nt=unique(cellfun(@(x)size(x,2),DVs));
    if numel(nt)>1
        error('All DVs must have identical numbers of timepoints.');
    end        
    if nt~=numel(time_s)
        error('Length of "time_s" does not match number of timepoints in DVs.');        
    end
    
    corrs.nregions=numel(DVs);
    
    %% parse and validate name-value args
    p=inputParser;
    p.addParameter('DVs_shuffled',cell(corrs.nregions,1),@(x)validateattributes(x,{'cell'},{'numel',corrs.nregions}));
    p.addParameter('time_lim_s',[-Inf Inf],@(x)validateattributes(x,{'numeric'},{'nonnan'}));
    p.parse(varargin{:});
    params = p.Results;    
    DVs_shuffled=params.DVs_shuffled;
    params=rmfield(params,'DVs_shuffled');
    
    if size(params.time_lim_s,2)~=2
        error('time_lim_s must be either [1x2] or [ntrialsx2]');
    end
    if size(params.time_lim_s,1)==1
        params.time_lim_s = repmat(params.time_lim_s,[ntrials 1]);
    end
    
    %% apply time limits
    tidx = time_s>params.time_lim_s(:,1) & time_s<params.time_lim_s(:,2);
    apply_time_lim = ~all(tidx(:));
    if apply_time_lim
        for i=1:corrs.nregions
            DVs{i}(~tidx)=NaN;
            DVs{i} = DVs{i}(:,any(tidx));
        end
        time_s = time_s(any(tidx));
        if ~ismember('DVs_shuffled',p.UsingDefaults)        
            for i=1:corrs.nregions
                for n=1:numel(DVs_shuffled{i})
                    if any(size(DVs_shuffled{i}{n})~=[ntrials,nt])
                        error('Size of DVs_shuffled does not match size of DVs');
                    end
                    DVs_shuffled{i}{n}(~tidx)=NaN;
                    DVs_shuffled{i}{n} = DVs_shuffled{i}{n}(:,any(tidx));
                end
            end        
        end
    end        
    corrs.time_s=time_s;
    corrs.lags=unique(round(corrs.time_s - corrs.time_s',6));             
    

    %% calculate correlations
    for i=corrs.nregions:-1:1
         z = (DVs{i} - nanmean(DVs{i},'all') ) ./ nanstd(DVs{i},[],'all');
         bad = abs(z)>4;
         DVs{i}(bad)=NaN;
        [corrs.std(i,1),corrs.se.std(i,1)] = DV.unbiased_std(DVs{i} (:));
        [corrs.std_timecourse(i,:),corrs.se.std_timecourse(i,:)] = DV.unbiased_std(DVs{i});
         %DVs{i} = DVs{i} ./ corrs.std(i); % equalize variance across
        % timepoints. makes no diff for timepoint based corr calculation
        % but for single value across timepoints it does. but empirically
        % makes little diff.
        % for j=1:numel(DVs_shuffled{i})
        %     DVs_shuffled{i}{j} = DVs_shuffled{i}{j} ./ corrs.std(i);
        % end
    end
    for i=corrs.nregions:-1:1
        DV1=DVs{i};
        parfor k=1:corrs.nregions
            output(i,k) = mainLoop(DV1,DVs{k},DVs_shuffled{k}); 
        end
        % for k=1:corrs.nregions
        %     if isempty(output(i,k).corr)
        %         output(i,k) = output(k,i);
        %     end
        % end
    end 
   
    %% post-process correlations
    for i=corrs.nregions:-1:1
        for k=corrs.nregions:-1:1
            fields=fieldnames(output);
            fields=fields(fields~="se");
            for f=1:numel(fields)
                corrs.(fields{f})(i,k,:,:) = output(i,k).(fields{f}); 
            end
            fields=fieldnames(output(1).se);
            for f=1:numel(fields)
                corrs.se.(fields{f})(i,k,:,:) = output(i,k).se.(fields{f}); 
            end            
        end
    end
   
end

%% helper functions

function corrs = mainLoop(DV1,DV2,DV2_shuffled)
    [corrs.corr_lags,corrs.se.corr_lags]=DV.corrPearson(DV1,DV2);  
    nan_block = NaN(size(DV1));
    DV1_cat = [nan_block DV1 nan_block]';
    DV1_cat=DV1_cat(:);
    DV2_cat = [nan_block DV2 nan_block]';
    DV2_cat=DV2_cat(:);    
    max_lag = size(DV1,2)-1;
    count=0;
    for i=-max_lag:max_lag
        count=count+1;
        if i<=0
            [corrs.xcorr(count) corrs.se.xcorr(count)] = DV.corrPearson(DV2_cat(1:(end-abs(i))),DV1_cat((1+abs(i)):end));
        else
            [corrs.xcorr(count) corrs.se.xcorr(count)] = DV.corrPearson(DV1_cat(1:(end-abs(i))),DV2_cat((1+abs(i)):end));
        end
    end
   % [corrs.xcorr,corrs.se.xcorr] = DV.get_xcorr(corrs.corr_lags,corrs.se.corr_lags);   
    [corrs.corr,corrs.se.corr]=DV.corrPearson(DV1(:),DV2(:));    
    corrs.corr_timecourse =  diag(squeeze(corrs.corr_lags));
    corrs.se.corr_timecourse =  diag(squeeze(corrs.se.corr_lags));    
    n_resamples=numel(DV2_shuffled);
    if ~isempty(DV2_shuffled)
        for n=n_resamples:-1:1
            [cfl(:,:,n),cfl_se(:,:,n)]=DV.corrPearson(DV1,DV2_shuffled{n});   
            [cf(n),cf_se(n)]=DV.corrPearson(DV1(:),DV2_shuffled{n}(:));       
        end
        corrs.correction_factor_lags = squeeze(nanmean(cfl,3));
        corrs.se.correction_factor_lags = squeeze(nanmean(cfl_se,3))./sqrt(n_resamples);
        corrs.correction_factor = nanmean(cf);  
        corrs.se.correction_factor = nanmean(cf_se)./sqrt(n_resamples);  
        [corrs.xcorr_correction_factor,corrs.se.xcorr_correction_factor] = DV.get_xcorr(corrs.correction_factor_lags,corrs.se.correction_factor_lags);    
        corrs.corrected_lags = rectify_corr(corrs.corr_lags-corrs.correction_factor_lags);    
        corrs.corrected = rectify_corr(corrs.corr - corrs.correction_factor);           
        corrs.correction_factor_timecourse =  diag(squeeze(corrs.correction_factor_lags));   
        corrs.se.correction_factor_timecourse =  diag(squeeze(corrs.se.correction_factor_lags));  
        corrs.corrected_timecourse = rectify_corr(corrs.corr_timecourse - corrs.correction_factor_timecourse);        
        corrs.se.corrected = sqrt(corrs.se.corr.^2 + corrs.se.correction_factor.^2);
        corrs.se.corrected_timecourse = sqrt(corrs.se.corr_timecourse.^2 + corrs.se.correction_factor_timecourse.^2);
        corrs.se.corrected_lags = sqrt(corrs.se.corr_lags.^2 + corrs.se.correction_factor_lags.^2);  
        [corrs.xcorr_corrected,corrs.se.xcorr_corrected] = DV.get_xcorr(corrs.corrected_lags,corrs.se.corrected_lags);          
    end  
end

function rho = rectify_corr(rho)
    nans=isnan(rho);
    rho = min(max(rho,-1),1);
    rho(nans)=NaN;
end


function corrs = mainLoop_cov(DV1,DV2,DV2_shuffled)
    [corrs.corr_lags,corrs.se.corr_lags]=mycov(DV1,DV2);  
    [corrs.xcorr,corrs.se.xcorr] = DV.get_xcorr(corrs.corr_lags,corrs.se.corr_lags);   
    [corrs.corr,corrs.se.corr]=mycov(DV1(:),DV2(:));    
    corrs.corr_timecourse =  diag(squeeze(corrs.corr_lags));
    corrs.se.corr_timecourse =  diag(squeeze(corrs.se.corr_lags));    
    n_resamples=numel(DV2_shuffled);
    if ~isempty(DV2_shuffled)
        for n=n_resamples:-1:1
            [cfl(:,:,n),cfl_se(:,:,n)]=mycov(DV1,DV2_shuffled{n});   
            [cf(n),cf_se(n)]=mycov(DV1(:),DV2_shuffled{n}(:));       
        end
        corrs.correction_factor_lags = squeeze(nanmean(cfl,3));
        corrs.se.correction_factor_lags = squeeze(nanmean(cfl_se,3))./sqrt(n_resamples);
        corrs.correction_factor = nanmean(cf);  
        corrs.se.correction_factor = nanmean(cf_se)./sqrt(n_resamples);  
        [corrs.xcorr_correction_factor,corrs.se.xcorr_correction_factor] = DV.get_xcorr(corrs.correction_factor_lags,corrs.se.correction_factor_lags);    
        corrs.corrected_lags = (corrs.corr_lags-corrs.correction_factor_lags);    
        corrs.corrected = (corrs.corr - corrs.correction_factor);           
        corrs.correction_factor_timecourse =  diag(squeeze(corrs.correction_factor_lags));   
        corrs.se.correction_factor_timecourse =  diag(squeeze(corrs.se.correction_factor_lags));  
        corrs.corrected_timecourse = (corrs.corr_timecourse - corrs.correction_factor_timecourse);        
        corrs.se.corrected = sqrt(corrs.se.corr.^2 + corrs.se.correction_factor.^2);
        corrs.se.corrected_timecourse = sqrt(corrs.se.corr_timecourse.^2 + corrs.se.correction_factor_timecourse.^2);
        corrs.se.corrected_lags = sqrt(corrs.se.corr_lags.^2 + corrs.se.correction_factor_lags.^2);  
        [corrs.xcorr_corrected,corrs.se.xcorr_corrected] = DV.get_xcorr(corrs.corrected_lags,corrs.se.corrected_lags);          
    end  
end

function [c,se] = mycov(x,y)
    [nobs,ncolx] = size(x);
    [nobs2,ncoly] = size(y);
    if nobs~=nobs2
        error('gg');
    end
    se=NaN(ncolx,ncoly);
    c=NaN(ncolx,ncoly);
    for i=1:ncolx
        thisx=x(:,i);  
        nanx = isnan(thisx);
        for j=1:ncoly
            thisy=y(:,j);
            nans = nanx | isnan(thisy);
            nok=sum(~nans);
            if nok
                thisxo = thisx(~nans);
                thisyo=thisy(~nans);
                thisxo = thisxo - sum(thisxo)./nok;
                thisyo = thisyo - sum(thisyo)./nok;
                c(i,j) = (thisxo'*thisyo) ./ (nok-1);
            end
        end
    end
end
