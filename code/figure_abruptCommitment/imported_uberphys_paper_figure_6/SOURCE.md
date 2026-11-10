# Imported source: `uberphys_paper/code/figure_6` (`ntc histograms`)

Copied into bondy_charlton_luo_2026 on 2026-11-10 as the code/plots behind v7 panels (Adrian's decision, same route as D1).

- **Origin:** `uberphys_paper` repo, `code/figure_6/ntc histograms.*`, as committed at `94ecc82de19ac4a1cb41d6c3023f2d684b777267` (= `e20536b^`). The files were deleted from uberphys_paper in `e20536b` (2026-04-17, "reorg"). Added by Adrian Bondy 2025-06-03 (`667483f`); last content change `a8df3b4` (Adrian, 2026-01-09).
- **Serves:**
  - v7 Figure 7 panel a, bottom histogram: right subplot, nTc-M1 − movement onset. **High** (15 relative bar heights within 0.02 of v7).
  - v7 Figure S15 panel a, left (first click) and right (movement onset) histograms. **High** (same method).
  - Note: the v7 y-axes read ~20–25% (7A) and ~17% (S15A) higher than this script's own axes. This looks like an assembly stretch; the code is probably right and the figure is to be fixed (Adrian, 2026-11-10). Evidence: `_work/RESEARCH_EVIDENCE.md`.
- **Copied (4):** `ntc histograms.m`, `ntc histograms.fig`, `ntc histograms.pdf`, `ntc histograms.png` (byte-identical to the git blobs).
- **Not copied:** nothing else; there were no other `ntc histograms` files at that commit.

The script loads its own DVs (`DV.load_DVs(..., 'ref_event','committime_s_M1', ...)`) and then loops over `i=1:5`, so the histograms pool **5 sessions**, not all 19. The S15A legend says "across all trials", so this is a possible legend/data question for later (data issues are tabled). Paths and inputs get made runnable here in a later step.
