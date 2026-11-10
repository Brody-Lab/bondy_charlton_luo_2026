# Imported source: `UberPhys/adrian/analysis/2026_05_11_sigmoid_fitting_fig_6`

Copied into bondy_charlton_luo_2026 on 2026-11-10 as the code/plots behind v7 panels (Adrian's decision, same route as D1).

- **Origin:** `UberPhys` repo, folder `adrian/analysis/2026_05_11_sigmoid_fitting_fig_6`, last commit `d16db499adb13f69f388d24d70030eb7c96524e7 2026-06-26 Adrian Bondy` (copied from the committed version; the working tree had no other changes).
- **Serves:**
  - v7 Figure 7 panel k (per-region click/DV correlation with dashed trilinear fits): `trilinear_fits.m` → `trilinear_fits.*`. **Medium** (layout and curves by eye; restyled in v7).
  - v7 Figure 7 panel m (drop time and drop duration per region): `plot_trilinear_summary.m` → `plot_trilinear_summary.*`. **Medium** (same layout and values by eye; v7 x-range trimmed).
  - Both use the class `Trilinear.m`. Their input curves come from `make_dv_corr_data_fig_abruptCommitment.m` (already in `code/figure_abruptCommitment/`).
  - The cumulative-Gaussian, logistic, normal and synthetic-recovery files are not in v7. `readme.md` documents the comparison. They stay together until the rename map sorts them (probably to `extra/`).
- **Copied (67):** every committed file in the folder: 21 `.m`, 16 `.fig`, 13 `.pdf`, 16 `.png`, `readme.md` (byte-identical to the git blobs).
- **Not copied:** `.asv` autosaves (2 files, untracked in UberPhys: `CumulativeGaussian.asv`, `CumulativeNormal.asv`).

Paths inside these scripts still point to their original locations; making them runnable here is a later step.
