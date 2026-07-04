function regions = get_brain_regions()
    % default list of brain regions to include for analysis
    % regions in Cells file will not include these names unless you first
    % run `regions = uberphys.simply_region_names(Cells.region)`
    regions = ["dmFC" "ADS" "M1"  "S1"   "mPFC" "MGB"  "TS" "BLA" "HPC" "NAc"  ];        % figure 2 order
end
