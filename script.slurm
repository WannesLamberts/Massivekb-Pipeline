#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -A ap_adrem_wb_thesis2425
#SBATCH --time=1:00:00
#SBATCH --partition=zen2

module purge
module load calcua/2024a
module load Nextflow/23.04.2
nextflow run main.nf -entry run_tasks -c config_files/supercomputer.config --input_tasks input_files/to.tsv --out_dir ${VSC_DATA}/results --work_dir ${VSC_SCRATCH}/work  --clusterOptions "-t 20:00:00 -c 1"