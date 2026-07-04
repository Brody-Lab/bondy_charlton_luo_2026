function options = importoptions(optionspath)
%{
Import a table of the format `options`

In a table of this format, each row corresponds to a variant of a statistical model. Each column
refers to a feature of the model variant. Two features that must be specified for each model variant
is `inputpath` and `outputfolder`

ARGUMENT
-`optionspath`: absolute path of the CSV table

OUTPUT
-a MATLAB table
%}
options = readtable(optionspath, 'Delimiter', ',');
for column = string(options.Properties.VariableNames)
    if iscellstr(options.(column))
        options.(column) = string(options.(column));
    end
end
if ispc
    for column = ["inputpath", "outputfolder"]
        options.(column) = UBT.cup2windows(options.(column));
    end
end