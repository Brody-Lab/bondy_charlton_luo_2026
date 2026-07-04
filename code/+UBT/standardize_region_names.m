function names = standardize_region_names(names)
% Standardize the names of brain regions
%
% ARGUMENT
%
%   names
%       an array of type `string`
%
% RETURN
%
%   names
%       a `string` array the same size as the argument `names`
validateattributes(names, {'string'}, {})
names(names=="Cg1" | names == "M2") = "dmFC";
names(names=="PrL" | names == "MO") = "mPFC";
names(names=="DGd" | names == "DGv" | names == "CA1") = "HPC";
names(names=="") = "unknown";