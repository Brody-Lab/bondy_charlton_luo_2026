# Imported source: `UberPhys/kaiyue/` (Fig 7J–M helpers and leave-one-out nTc files)

Copied into bondy_charlton_luo_2026 on 2026-11-10 (Adrian's decision, same route as D1). Kaiyue wrote most of these, but Adrian used them for Fig 7J–M, so he brings them in.

- **Origin:** `UberPhys` repo at `5a6dbdf9225cc22777e8fdcf07011a2d221c65d8` (committed versions; no uncommitted changes to these files).
  - `functions/colMeanPixels.m`, `functions/subtractMean.m`: from `kaiyue/functions/`, Kaiyue 2026-04-24 (`b69eda1c`).
  - `functions/diagonalMean.m`, `functions/mean_corr.m`, `functions/realign_data_mom.m`: from `kaiyue/functions/`, Kaiyue 2026-04-24. Adrian edited all three 2026-05-18 (`d0081e13`): different pooling in `mean_corr`, and rounding to 3 decimals instead of 2.
  - `get_binned_delta_clicks.m`: from `kaiyue/get_binned_delta_clicks.m`, added by Adrian 2026-01-27 (`83f3f14d`). This is the copy that resolved on Adrian's path. Three other plain copies (`kaiyue/functions/`, `kaiyue/2.26/`, `kaiyue/2.5/`) differ only in the default `interval` and in comments. The Fig 7 callers pass `'interval',[0,1]`, so for Fig 7 all four give identical results (High, code read).
  - `nTc_Loo_0314/*.mat` (20 files, 2.7 MB): from `kaiyue/nTc_Loo_0314/`, Kaiyue 2026-04-24 (`b69eda1c`). These are leave-one-region-out nTc per session, probably converted from Eva Yi Xie's Mar-2026 LOO csv (provenance is a data-step question).
- **Serves:** v7 Figure 7 panels j–m, via `code/figure_abruptCommitment/make_dv_corr_data_fig_abruptCommitment.m` (and its `_ed` copy for the per-rat versions). The v7 plots were last regenerated 2026-05-27, after the 05-18 helper edits, and no helper changed afterwards, so these are the versions that made v7 (Medium-High).
- **Copied (26):** 5 `functions/*.m`, `get_binned_delta_clicks.m`, 20 `nTc_Loo_0314/*.mat` (byte-identical to the git blobs).
- **Not copied:** the other `kaiyue/functions/` files (`DS_colMeanPixels`, `glmnet_get_weights`, `linearReg`, `projFR_norm`, `realign_data`, `trialFolds`), which Fig 7 doesn't use, and the `2.26/`, `2.5/` copies.

The script still loads the LOO files from the hard-coded `C:\github\UberPhys\kaiyue\nTc_Loo_0314\` (line 190). Pointing it at a data root, and moving the `.mat` files to the shared data location, are part of the data step.
