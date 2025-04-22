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
chmod +x bin/calibrate.py

export TOWER_ACCESS_TOKEN=eyJ0aWQiOiAxMDgxOX0uMGVkMzY4YWVjYzk4OGViNGY3MzQ2MmQ4YjIxMjMxNDM2MDgzNjY2Ng==
export TOWER_WORKSPACE_ID=248391247643063


nextflow run main.nf \
    -c config_files/slurm.config \
     -entry calibrate\
     --input ${VSC_SCRATCH}/psms\
     --chronologer ${VSC_SCRATCH}/Massivekb-pipeline/Chronologer.tsv \
     --out_dir ${VSC_DATA}/results \
    --work_dir ${VSC_SCRATCH}/work \
     --max_processes 50 \
    --clusterOptions "-t 24:00:00 -c 1 --mem-per-cpu=7680m" \
     -with-tower \
     -with-apptainer
