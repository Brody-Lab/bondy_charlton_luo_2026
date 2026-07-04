clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);

T = readtable(fullfile(analysispath, "nTc_augmented.csv"), 'delimiter', ',');

indices = ~isnan(T.nTc);
mdl = fitlm([T.absratediff(indices), T.clicks_dur_s(indices)], T.nTc(indices), 'interactions');
C = mdl.Coefficients;

C.Properties.RowNames{2} = [C.Properties.RowNames{2} '  (abs. click rate diff.)'];
C.Properties.RowNames{3} = [C.Properties.RowNames{3} '  (click stimulus duration)'];

writetable(C, fullfile(analysispath, [scriptname '.csv']), 'delimiter', ',', 'WriteRowNames',true)