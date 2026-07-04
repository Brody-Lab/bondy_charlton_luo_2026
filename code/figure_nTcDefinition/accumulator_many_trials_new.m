lbups = [0.1  0.36 0.45 1.3 1.4];
rbups = [0.2  0.73 0.8 0.88 1 1.6 1.7 1.88];

% k=k+1;
% rbups = Cells{1}.Trials.leftBups{k}*2;
% lbups = Cells{1}.Trials.rightBups{k}*2;


sigma_s = [ 0.03];
sigma_a = 0.11;
bound=3;

timesteps = 200;
dt = 2./timesteps;

t = linspace(0,2,timesteps);
figure;

for i=1:5

noise = sigma_a*normrnd(0,1,timesteps,1);

signal = zeros(timesteps,1);

signal(round(lbups./dt))=-1+normrnd(0,sigma_a,numel(lbups),1);
signal(round(rbups./dt))=1+normrnd(0,sigma_a,numel(rbups),1);
kernel = [0 1 0.5 0]';
signal=filterArray(signal,kernel);
acc=cumsum(signal+noise);
a=find(abs(acc)>bound,1);

if ~isempty(a)
    acc(a:end)=bound *sign(acc(a));
end
plot(t,acc);hold on

end
hold on;
line(repmat(lbups,2,1),repmat([4 5],numel(lbups),1)','color','b');
line(repmat(rbups,2,1),repmat([6 7],numel(rbups),1)','color','r');