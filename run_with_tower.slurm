#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -A ap_adrem_wb_thesis2425
#SBATCH --time=20:00:00
#SBATCH --partition=zen2

module purge
module load calcua/2024a
module load Nextflow/23.04.2

chmod +x bin/get_psm.py
chmod +x bin/get_tasks.py
chmod +x bin/parse.py

export TOWER_ACCESS_TOKEN=0
export TOWER_WORKSPACE_ID=0

nextflow run main.nf \
    -entry run_tasks \
    -c config_files/supercomputer.config \
    --input_tasks input_files/to.tsv \
    --out_dir ${VSC_DATA}/results \
    --work_dir ${VSC_SCRATCH}/work \
    --clusterOptions "-t 20:00:00 -c 1" \
    -with-tower