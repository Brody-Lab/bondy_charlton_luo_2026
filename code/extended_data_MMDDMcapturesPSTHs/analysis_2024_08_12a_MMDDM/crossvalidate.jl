# load the module
using FHMDDM
csvpath = ARGS[1]
row = parse(Int, ARGS[2])
options = Options(csvpath,row)
println(options.datapath)
model = Model(csvpath, row)
FHMDDM.crossvalidate_analyze_save(5,model)