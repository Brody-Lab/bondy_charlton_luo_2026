clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
T = UBT.tabulateoptions(fullfile(fileparts(analysispath), 'analysis_2024_08_08a_MMDDM_uberphys'));
T.datapath = TZL.windows2cup(T.datapath);
T.outputpath = TZL.windows2cup(T.outputpath);

T1 = T;
for i = 1:height(T1)
    T1.outputpath{i} = strrep(T1.outputpath{i}, 'ALL', 'multimode');
    T1.fit_beta = true(height(T1),1);
end
T2 = T;
for i = 1:height(T)
    T2.outputpath{i} = strrep(T2.outputpath{i}, 'ALL', 'singlemode');
    T2.fit_beta = false(height(T2),1);
end
T = [T1;T2];
writetable(T, fullfile(analysispath, [scriptname '.csv']))
