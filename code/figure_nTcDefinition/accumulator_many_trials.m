

lbups = [0.1  0.36 0.45 0.6 1.3 1.4];
rbups = [0.2 0.55 0.73 0.8 0.88 1 1.6 1.67 1.78 1.88];

% k=k+1;
% rbups = Cells{1}.Trials.leftBups{k}*2;
% lbups = Cells{1}.Trials.rightBups{k}*2;


sigma_s = [ 0.16];
sigma_a = 0.2;
bound=3;

timesteps = 50;
dt = 2./timesteps;

t = linspace(0,2,timesteps);
figure;

for i=1:100

noise = sigma_a*normrnd(0,1,timesteps,1);

signal = zeros(timesteps,1);

signal(round(lbups./dt))=-1+normrnd(0,sigma_a,numel(lbups),1);
signal(round(rbups./dt))=1+normrnd(0,sigma_a,numel(rbups),1);
kernel = [0 0 0.2 0.7 1 0.9 0.6 0.4 0.2]';
signal=filterArray(signal,kernel);
acc=cumsum(signal+noise);
a=find(abs(acc)>bound,1);

if ~isempty(a)
    acc(a:end)=bound *sign(acc(a));
end
d = acc+filterArray(normrnd(0,0.6,timesteps,1),gausswin(10,2));
plot(t,d);hold on
end

for i=1:numel(lbups)
    line([1 1]*lbups(i),[-0.5 0.5]+4,'color','r');
end

for i=1:numel(rbups)
    line([1 1]*rbups(i),[-0.5 0.5]+5,'color','c');
end