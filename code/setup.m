% set up paths
code_path = fileparts(which(mfilename));
repo_path = fileparts(code_path);
addpath(genpath(repo_path));

% set up default plotting behavior
set(groot,'defaultfigurecolor','w');
set(groot,'defaultAxesLinewidth',1);
set(groot,'defaultLineLinewidth',1);
set(groot,'defaultAxesfontsize',18);
set(groot,'defaultAxestickdir','out');
set(groot,'defaultAxestickdirmode','manual');
set(groot,'defaultAxesxcolor',[0 0 0]);
set(groot,'defaultAxesycolor',[0 0 0]);
set(groot,'defaultfigurecolor','w');
set(groot,'defaultAxesBox','off');
set(groot,'defaultAxesLabelFontSizeMultiplier',1);
set(groot,'defaultTextFontSize',14);

right_color = [141 4 175]/255;
left_color = [0 174 239]/255;