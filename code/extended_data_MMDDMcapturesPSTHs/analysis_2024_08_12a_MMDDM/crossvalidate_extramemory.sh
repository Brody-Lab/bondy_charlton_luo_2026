#!/usr/bin/env bash

#SBATCH --job-name=12a_cv
#SBATCH --array=3,4,5,7,23,24,25,26
#SBATCH --output=/mnt/cup/labs/brody/tzluo/analysis_data/analysis_2024_08_12a_MMDDM/slurm.%A.%a.out
#SBATCH --error=/mnt/cup/labs/brody/tzluo/analysis_data/analysis_2024_08_12a_MMDDM/slurm.%A.%a.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --partition Brody
#SBATCH --cpus-per-task 5
#SBATCH --mem=124666
#SBATCH --time=72:00:00
#SBATCH --mail-user=zhihaol@princeton.edu
#SBATCH --mail-type=all

analysisname="analysis_2024_08_12a_MMDDM"
scriptsfolderpath="/usr/people/zhihaol/Documents/tzluo/analyses/${analysisname}"
juliascript_path="${scriptsfolderpath}/crossvalidate.jl"
options_csv_path="${scriptsfolderpath}/models.csv"

module load julia/1.6.0
LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p $datapaths_path)
echo $LINE
julia -p 5  $juliascript_path $options_csv_path $SLURM_ARRAY_TASK_ID
