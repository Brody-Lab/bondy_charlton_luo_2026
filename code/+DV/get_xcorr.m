function [xcorr,xcorr_se] = get_xcorr(lags,lags_se)
    xl = size(lags,1)-1;
    d = -xl:xl;
    xcorr = spdiags(lags,d);
    xcorr(xcorr==0)=NaN;

    if nargin>1 && nargout>1
        xcorr_se = spdiags(lags_se,d);
        xcorr_se(xcorr_se==0)=NaN;
       

    end
    xcorr2 = nanmean(xcorr);        
   % [xcorr,xcorr_se] = DV.average_corrs(xcorr,xcorr_se,1);
    xcorr = xcorr2;  
end