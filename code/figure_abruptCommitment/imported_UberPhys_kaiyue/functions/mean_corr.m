function [cor, len, r_lower, r_upper] = mean_corr(matX, matY, idxX, idxY)

% matX: (ntrials, ntimes_X), matrix on x axis, like delta_clicks_aligned
% matY: (ntrials, ntimes_Y), matrix on y axis, like DV_aligned
% idxX: vector, column indices, which columns are computed
% idxY: vector, row indices, which rows are considered in the mean
% matrix(idxY, idxX): pixels included

% cor: scalar, mean correlation of the column
% len: how many trials are taken
% r_lower: scalar, cor - error_low
% r_upper: scalar, cor + error_up

lenY1 = size(matX,1);
lenY2 = size(matY,1);
if lenY1 ~= lenY2 | length(idxX) ~= length(idxY)
    disp('Wrong input shape');
end
X=matX(:,idxX);
Y=matY(:,idxY);
X=X(:);
Y=Y(:);
good = (~isnan(X) & ~isnan(Y));
len=sum(good);

[cor,~,r_lower,r_upper] = corrcoef(X(good),Y(good));
cor=cor(2);
r_lower=r_lower(2);
r_upper=r_upper(2);

    % z = 0.5 * log((1+cor)/(1-cor));
    % se_z = 1/sqrt(len-3);
    % 
    % z_lower = z - 1.96*se_z;
    % z_upper = z + 1.96*se_z;
    % 
    % r_lower = tanh(z_lower);
    % r_upper = tanh(z_upper);

end
