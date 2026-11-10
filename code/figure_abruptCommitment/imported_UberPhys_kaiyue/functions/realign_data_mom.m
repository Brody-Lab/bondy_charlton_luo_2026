function [data_aligned,time_s] = realign_data_mom(data,time_s,t0,time_lim)

        % "data" is some continuously evolving variable, sampled evenly at times
        % in "time_s" across many trials. It is a matrix of size ntrials
        % x ntimepoints. (e.g. "decision variable" estimated from
        % neural activity across many trials).

        % This function will realign the data relative to some event that occurs with
        % variable timing on each trial (e.g. neurally-inferred time of commitment).
        % The time of the event on each trial is given by "t0".

        % "time_lim" is a 2-element vector giving the range of times
        % (relative to t0) you want to include in the realigned data.

        % If this desired range extends outside of the range of the
        % original data on some trials, these values will be filled with NaNs.

        % The sampling resolution of the realigned data will match the
        % sampling resolution of the input data.
        
        % data: (ntrials, ntimes)
        % times_s: (ntimes,1)
        % t0: (ntrials,1) nTc-fc
        % time_lim: (2,1)

        validateattributes(data,{'numeric'},{'nonempty','ndims',2},mfilename,'DV',1);
        [ntrials,ntimepoints] = size(data);
        validateattributes(time_s,{'numeric'},{'vector','numel',ntimepoints},mfilename,'time_s',2);
        validateattributes(t0,{'numeric'},{'vector','numel',ntrials},mfilename,'t0',3);
        if nargin>3
            validateattributes(time_lim,{'numeric'},{'vector','numel',2,'increasing'});
        end


        % resolution_s = 0.05
        resolution_s = unique(round(diff(time_s),6));
        if ~isscalar(resolution_s)
            error('Bins must be evenly spaced.');
        end
           
        offset_bins = round((t0-0.025)./resolution_s); % nTc bin - 1; how many bins to shift nTc to the 0.025 bin
        leftpad = max(0,max(offset_bins));
        rightpad = max(0,max(-offset_bins));     
        time_s = (-leftpad:(rightpad+numel(time_s)-1))*resolution_s;
        data_aligned = shiftrows(data,offset_bins);
        if nargin>3
            idx = round(time_s,3)>=time_lim(1) & round(time_s,3)<=time_lim(2);
            time_s = time_s(idx);
            data_aligned=data_aligned(:,idx);
        end
end

% nTc bin is leftpad+1
function [X,leftpad,rightpad] = shiftrows(X,offset)
    m=size(X,1);
    leftpad = max(0,max(offset));
    rightpad = max(0,max(-offset));
    X = [NaN(m,leftpad) X NaN(m,rightpad)];
    for i=1:m
        X(i,:) = circshift(X(i,:),-offset(i));
    end
end