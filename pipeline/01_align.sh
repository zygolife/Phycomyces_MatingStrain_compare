#!/usr/bin/bash -l
#SBATCH -N 1 -N 1 -c 16 --mem 32gb --out logs/align.%a.log --time 8:00:00 -a 1
module load minimap2
module load samtools
module load picard
module load gatk/4
module load workspace/scratch
MEM=32g

TEMP=$SCRATCH

if [ -f config.txt ]; then
  source config.txt
fi
TEMP=$SCRATCH
if [ -z $REFGENOME ]; then
  echo "NEED A REFGENOME - set in config.txt and make sure 00_index.sh is run"
  exit
fi

if [ ! -f $REFGENOME.dict ]; then
  echo "NEED a $REFGENOME.dict - make sure 00_index.sh is run"
fi
mkdir -p $TMPOUTDIR $ALNFOLDER $UNMAPPED

CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
  N=$1
fi
if [ -z $N ]; then
  echo "cannot run without a number provided either cmdline or --array in sbatch"
  exit
fi

MAX=$(wc -l $SAMPFILE | awk '{print $1}')
if [ $N -gt $MAX ]; then
  echo "$N is too big, only $MAX lines in $SAMPFILE"
  exit
fi

IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read STRAIN FILEBASE
do
  PREFIX=$STRAIN
  FINALFILE=$ALNFOLDER/$STRAIN.$HTCEXT
  echo "To process $PREFIX and $FINALFILE"
  if [ ! -s $FINALFILE ]; then
    BAMSTOMERGE=()
    for BASEPATTERN in $(echo $FILEBASE | perl -p -e 's/\;/,/g');
    do
	    BASE=$(basename $BASEPATTERN | perl -p -e 's/(\S+)\.filter\S+/$1/g; s/(\S+)_\[12\].+/$1/g; s/_R?$//g;')
      # END THIS PART IS PROBABLY PROJECT SPECIFIC
      echo "STRAIN is $STRAIN BASE is $BASE BASEPATTERN is $BASEPATTERN"

      TMPBAMFILE=$TEMP/$BASE.unsrt.sam
      SRTED=$TEMP/$BASE.srt.bam
      DDFILE=$TEMP/$BASE.DD.bam
      FINALFILE=$ALNFOLDER/$STRAIN.$HTCEXT
      READGROUP="@RG\tID:$BASE\tSM:$STRAIN\tLB:$BASE\tPL:PacBio\tCN:$RGCENTER"
      echo "$TMPBAMFILE $READGROUP"

      if [ ! -s $DDFILE ]; then
        if [ ! -s $SRTED ]; then
          if [ -e $PAIR1 ]; then
            if [ ! -f $SRTED ]; then
		    minimap2 -R "$READGROUP" -ax map-pb -t $CPU $REFGENOME $FASTQFOLDER/$BASEPATTERN > $TMPBAMFILE
		    samtools sort --threads $CPU -O bam -o $SRTED -T $TEMP $TMPBAMFILE
            fi
          else
            echo "Cannot find $BASEPATTERN, skipping $STRAIN"
            exit
          fi
        fi # SRTED file exists or was created by this block

        time picard MarkDuplicates -I $SRTED -O $DDFILE \
          -METRICS_FILE logs/$STRAIN.dedup.metrics -CREATE_INDEX true -VALIDATION_STRINGENCY SILENT
        if [ -f $DDFILE ]; then
          rm -f $SRTED
        fi
      fi # DDFILE is created after this or already exists
      BAMSTOMERGE+=( $DDFILE )
    done
    samtools merge -O BAM --threads $CPU $FINALFILE "${BAMSTOMERGE[@]}"
    samtools index $FINALFILE
    if [ -f $FINALFILE.crai ]; then
      rm -f "${BAMSTOMERGE[@]}"
      rm -f $(echo "${BAMSTOMERGE[@]}" | sed 's/bam$/bai/')
      rm -f $DDFILE 
      rm -f $(echo $DDFILE | sed 's/bam$/bai/')
    fi
  fi #FINALFILE created or already exists
  FQ=$(basename $FASTQEXT .gz)
  UMAP=$UNMAPPED/${STRAIN}.$FQ
  UMAPSINGLE=$UNMAPPED/${STRAIN}_single.$FQ
  #echo "$UMAP $UMAPSINGLE $FQ"

  if [ ! -f $UMAPSINGLE.gz ]; then
    samtools fastq -f 4 $FINALFILE | pigz -c > $UMAPSINGLE.gz
  fi
done
