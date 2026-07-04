function [DV,time_s] = realign_DVs(DV,time_s,t0,time_lim)
        
        validateattributes(DV,{'numeric'},{'nonempty','ndims',2},mfilename,'DV',1);
        [ntrials,nt] = size(DV);
        validateattributes(time_s,{'numeric'},{'vector','numel',nt},mfilename,'time_s',2);
        validateattributes(t0,{'numeric'},{'vector','numel',ntrials},mfilename,'t0',3);
        if nargin>3
            validateattributes(time_lim,{'numeric'},{'vector','numel',2,'increasing'});
        end


        
        resolution_s = unique(round(diff(time_s),6));
        if ~isscalar(resolution_s)
            error('Bins must be evenly spaced.');
        end

        offset_bins = round(round(t0,1)./resolution_s); % round number of bins relative to first bin center                             
        leftpad = max(0,max(offset_bins));
        rightpad = max(0,max(-offset_bins));     
        time_s = (-leftpad:(rightpad+numel(time_s)-1))*resolution_s + time_s(1);
        DV = shiftrows(DV,offset_bins);
        if nargin>3
            idx = time_s>=time_lim(1) & time_s<=time_lim(2);
            time_s = time_s(idx);
            DV=DV(:,idx);
        end
end


function [X,leftpad,rightpad] = shiftrows(X,offset)
    m=size(X,1);
    leftpad = max(0,max(offset));
    rightpad = max(0,max(-offset));
    X = [NaN(m,leftpad) X NaN(m,rightpad)];
    for i=1:m
        X(i,:) = circshift(X(i,:),-offset(i));
    end
end