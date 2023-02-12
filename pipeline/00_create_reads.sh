#!/usr/bin/bash -l
#SBATCH -p short -c 2 --mem 8gb -N 1 --out logs/wgsim.log

module load samtools
pushd genomes
curl -O https://genome.jgi.doe.gov/portal/ext-api/downloads/get_tape_file?blocking=true&url=/PhyblU21_2/download/_JAMO/5df01857e08d44553ef5b9dd/PhyblU21_2_AssemblyScaffolds.fasta.gz -b ../cookies
gunzip PhyblU21_2_AssemblyScaffolds.fasta.gz
popd
pushd input
wgsim -N 3000000 -e 0 -s 100 -1 150 -2 150 -r 0 -R 0 ../genome/PhyblU21_2_AssemblyScaffolds.fasta UBC21_R1.fq UBC21_R2.fq
pigz UBC21_R1.fq UBC21_R2.fq
