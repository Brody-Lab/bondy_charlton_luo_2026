function P = randder(n, m)
% p = randder(n)
% p = randder(n, m)
% Generate m sequence of random derangement of length n
%
% A derangement is a permutation of the elements of a set, such that no
% element appears in its original position.
%
% INPUT:
%   n: scalar integer >= 2, derangement length.
%   m: scalar integer, number of random vectors.
% OUTPUT:
%   p: array of size (m x n), such that
%      for every row=1,...,m
%        unique(P(row,:)) is equal to (1:n)
%        p(row,i) ~= i for all i = 1,2,....n.
%
% Base on: "Generating Random Derangement", Martinez Panholzer, Prodinger
% Remove the need inner loop by shrinking index table J (still not ideal)
%
% Author: Bruno Luong <brunoluong@yahoo.com>
% 
% History: 01-Mar-2021: Original
%          02-Mar-2021: speed optitization
% 
% See also: randperm
if nargin < 2
    m = 1;
end
if mod(n,1) || n < 2
    error('randder: n must be scalar integer >= 2')
end
utab = 2:n;
sfact = subfactorial(utab);
qtab = (utab-1).*[subfactorial([0 1]), sfact(1:end-2)]./sfact;
overflowed = ~isfinite(qtab);
qtab(overflowed) = 1./utab(overflowed);
P = rand(m,n);
R = rand(m,n);
for row = 1:m
    p = 1:n;
    b = true(1,n);
    u = n-1;
    J = 1:u;
    x = P(row,:);
    r = R(row,:);
    for i = n:-1:2
        if u <= 0
            break
        elseif b(i)
            k = ceil(x(i)*u);
            j = J(k);
            tmp = p(i);
            p(i) = p(j);
            p(j) = tmp;
            if r(i) < qtab(u)
                b(j) = false;
                J(k:u-1) = J(k+1:u);
                u = u-1;
            end
            u = u-1;
        end
    end
    P(row,:) = p;
end
end % randder
%%
function D = subfactorial(n)
D = floor((factorial(n)+1)/exp(1));
end