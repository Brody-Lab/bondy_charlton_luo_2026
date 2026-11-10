function [delta_clicks,bin_centers] = get_binned_delta_clicks(Trials,varargin)

    %calculate binned delta clicks (#R-#L) given a Trial structure describing the
    % clicks stimulus on a PBups session

    % default is 50ms bins relative to the first click

    % bins extending outside of the stimulus window (from stim_on to
    % stim_off) are filled with NaNs

    p=inputParser;
    p.KeepUnmatched=true;
    p.addParameter('ref_event','first_click',@(x)validateattributes(x,{'char','string'},{'nonempty'}));
    p.addParameter('resolution_s',0.05,@(x)validateattributes(x,{'numeric'},{'scalar','positive'}));
    p.addParameter('interval',[-0.025 1.2],@(x)validateattributes(x,{'numeric'},{'numel',2,'increasing'}));    % include this range of timepoints in predictions\
    p.addParameter('delay_s',0);
    p.parse(varargin{:});
    params=p.Results;
    
    nTrials = numel(Trials.is_hit);
    ref_event = Trials.stateTimes.(params.ref_event);
    edges = (params.interval(1):params.resolution_s:params.interval(2)) - params.delay_s;
    stim_on = Trials.stateTimes.first_click - ref_event;   
    stim_off = Trials.stateTimes.cpoke_req_end - ref_event;        
    delta_clicks = NaN(nTrials,numel(edges)-1);
    nans = edges(1:end-1)>stim_off | edges(2:end)<stim_on    ;
   for t=1:nTrials 
       if isnan(stim_on(t)) || isnan(stim_off(t)) || Trials.violated(t)
           continue
       end
       lbups = Trials.stateTimes.clicks_on(t) + Trials.leftBups{t} - ref_event(t);
       rbups = Trials.stateTimes.clicks_on(t) + Trials.rightBups{t} - ref_event(t);  
       lbups = matlab.internal.math.histcounts(lbups,edges);
       rbups = matlab.internal.math.histcounts(rbups,edges);
       delta_clicks(t,:) = rbups-lbups;
   end
   
   delta_clicks(nans)=NaN;

   bin_centers = (edges(1:end-1) + edges(2:end))/2;

       
   
end