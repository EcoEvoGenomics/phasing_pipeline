#!/bin/bash
# written 29/06/2023

# nextflow management script 

# Job name:
#SBATCH --job-name=nextflow_testing
#
# Project:
#SBATCH --account=nn10082k
#
# Wall clock limit (hh:mm:ss):
#SBATCH --time=120:00:00
#
# Processor and memory usage:
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=1

 # notify end of job
#SBATCH --mail-user=mark.ravinet@ibv.uio.no
#SBATCH --mail-type=FAIL

# move into directory
source ~/miniconda3/bin/activate
conda activate phase

cd /cluster/work/users/msravine/phasing_pipeline

# run nextflow pipeline
nextflow run phasing.nf --windows sparrow_genome_windows_test.list