#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -A ap_adrem_wb_thesis2425
#SBATCH --time=24:00:00
#SBATCH --partition=zen2

module purge
module load calcua/2024a
module load Nextflow/23.04.2

chmod +x bin/get_psm.py
chmod +x bin/get_tasks.py
chmod +x bin/parse.py
chmod +x bin/to_parquet.py

mkdir ${VSC_DATA}/results

export TOWER_ACCESS_TOKEN=eyJ0aWQiOiAxMDgxOX0uMGVkMzY4YWVjYzk4OGViNGY3MzQ2MmQ4YjIxMjMxNDM2MDgzNjY2Ng==
export TOWER_WORKSPACE_ID=248391247643063


nextflow run main.nf \
    -entry to_parquet\
    -c config_files/slurm.config \
    --out_dir ${VSC_DATA}/results \
    --work_dir ${VSC_SCRATCH}/work \
    --clusterOptions "-t 24:00:00 -c 1 --mem-per-cpu=32000m" \
    --max_processes 1 \
    --input ${VSC_SCRATCH}/psms \
    -with-tower