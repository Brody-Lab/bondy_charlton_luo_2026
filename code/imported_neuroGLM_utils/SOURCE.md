# Imported source: `neuroGLM/utils/empirical_p.m`

Copied into bondy_charlton_luo_2026 on 2026-11-10 as a helper that figure code calls but that was defined in no repo the paper code ships with (Adrian's decision, same route as D1).

- **Origin:** `Brody-Lab/neuroGLM` repo, `utils/empirical_p.m`, last commit `d98980b804b91bba0ab8c99447cce693baca5ae7 2022-12-07 Adrian Bondy` (copied from the committed version).
- **Why this copy:** on Adrian's MATLAB path, `which -all empirical_p` resolves to `neuroGLM/utils/empirical_p.m` (shadowing `labwide_PBups_analysis/helpers/`). An older variant in `abondy/stat/` (2020) is not on the path; it checks `all(isnan(x))` instead of `all(isnan(distribution))`. **High.**
- **Used by:** `code/extended_data_populationSizeAnalyses/ed_fig_populationSizeAnalyses_bc.m` (S4) and `code/figure_abruptCommitment/dv_corr_plots.m` (Fig 7J–M).
- **Copied (1):** `empirical_p.m` (byte-identical to the git blob).

Where shared helpers finally live is decided in the dependencies step (PLAN section 3, step 5).
