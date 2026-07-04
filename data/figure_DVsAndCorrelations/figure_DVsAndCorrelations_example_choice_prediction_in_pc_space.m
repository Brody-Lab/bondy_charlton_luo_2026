% requires other repos and access to cup
% predict_from_cells is the version in uberphys_paper, which reflects
% uberphys commit b4213a4 of DV.predict_from_cells (march 4 , 2025).

% this is here for traceability, and just to match the figure in the paper
% as closely as possible.
% in the future, using DV.predict_from_cells and updating the figure is better.

Cells = uberphys.load_Cells_files("A324_2023_07_21");
joined_Cells = join_cells_files(Cells);
joined_Cells = add_first_click_state(joined_Cells);
joined_Cells.hemisphere=joined_Cells.hemisphere(joined_Cells.sess_idx);
joined_Cells.Trials = remove_trials(joined_Cells.Trials,validate_trials(joined_Cells.Trials));
joined_Cells.region = uberphys.simplify_region_names(joined_Cells.region);
[res,binned_spikes] = predict_from_cells(joined_Cells,'variable','choice','regions','dmFC','hemisphere',["left" "right"],'npcs',2);
save(fullfile(repo_path,'data/figure_DVsAndCorrelations/figure_DVsAndCorrelations_example_choice_prediction_in_pc_space.mat'),'res','binned_spikes');