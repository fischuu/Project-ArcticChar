# run the GBS snakemake pipeline on the puhti cluster
#
# Before you start, take care that the following two files are available:
# rawsamples
#     RUN: find /scratch/project_2003491/ArcticChar/FASTQ/RAW/ -name '*R1_001.fastq.gz' | xargs -n1 basename | sed 's/_R1_001.fastq.gz//g' >  /scratch/project_2003491/ArcticChar/rawsamples
# barcodesID.txt
#     FORMAT:   INDEX \ tab SampleName \tab BOOL, include in mock reference?
# Remove all unnecessary lines from samplesheet.csv and then rrun:

grep -i "Artic_charr" /scratch/project_2001881/201204_NB551722_0018_AH2HWGBGXF/SampleSheet.csv | \
awk 'BEGIN {FS=","; OFS="\t"} {print $4"+"$6, $1 ,"NO"}' > /scratch/project_2003491/ArcticChar/barcodesID_Geno18.txt

grep -i "Arctic_charr" /scratch/project_2001881/201214_NB551722_0019_AHYGCTBGXC/SampleSheet.csv | \
awk 'BEGIN {FS=","; OFS="\t"} {print $8"+"$6, $1 ,"NO"}' | tail -n +2 | tr -d ' ' > /scratch/project_2003491/ArcticChar/barcodesID_Geno19.txt

cat /scratch/project_2003491/ArcticChar/barcodesID_Geno18.txt /scratch/project_2003491/ArcticChar/barcodesID_Geno19.txt | sed '/CS/d' |  sed '/PstI/d' | sed '/LB/d' | awk '{print $1"\t"$2"_\t"$3}' > /scratch/project_2003491/ArcticChar/barcodesID.txt

module load bioconda/3
source activate /projappl/project_2001746/conda_envs/Genotype

# Create the rulegraph (For large workflows this might take a while, comment this out for development)
snakemake -s /scratch/project_2003491/Pipeline-GBS/GBS-pipeline.smk \
          --configfile /scratch/project_2003491/ArcticChar/GBS-pipeline_config-ArcticChar.yaml \
          --rulegraph | dot -T png > ./workflow.png
          
# Run the workflow
snakemake -s /scratch/project_2003491/Pipeline-GBS/GBS-pipeline.smk \
          -j 350 \
          --use-conda \
          --use-singularity \
          --singularity-args "-B /scratch:/scratch,/projappl:/projappl" \
          --configfile /scratch/project_2003491/ArcticChar/GBS-pipeline_config-ArcticChar.yaml \
          --latency-wait 60 \
          --cluster-config /scratch/project_2003491/ArcticChar/GBS-pipeline_puhti-config.yaml \
          --cluster "sbatch -t {cluster.time} --account={cluster.account} --gres=nvme:{cluster.nvme} --job-name={cluster.job-name} --tasks-per-node={cluster.ntasks} --cpus-per-task={cluster.cpus-per-task} --mem-per-cpu={cluster.mem-per-cpu} -p {cluster.partition} -D {cluster.working-directory}" \
          $1 
