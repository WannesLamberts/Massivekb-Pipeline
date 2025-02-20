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
chmod +x bin/failed_tasks.py

mkdir ${VSC_DATA}/results

nextflow run main.nf \
    -entry download_and_run_tasks \
    -c config_files/slurm.config \
    --out_dir ${VSC_DATA}/results \
    --work_dir ${VSC_SCRATCH}/work \
    --max_processes 10 \
    --clusterOptions "-t 24:00:00 -c 1" \
    -with-trace ${VSC_DATA}/results/trace.tsv