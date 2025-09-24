#!/bin/bash
# de novo assembly with SPAdes

# Step 1: Define base directory
BASEDIR="rawdata_50"
INPUT_DIR="$BASEDIR/trimmed_reads"
OUTPUT_BASE="$BASEDIR/assembly"

# Step 2: Create output base directory if it doesn't exist
mkdir -p "$OUTPUT_BASE"

# Step 3: Set SPAdes parameters
THREADS=10
MEMORY=16   # in GB

echo "Starting assembly..."

# Step 4: Loop through trimmed paired-end files
for f1 in "$INPUT_DIR"/*_1_trimmed.fastq.gz; do
  # Get corresponding read 2
  f2="${f1/_1_trimmed.fastq.gz/_2_trimmed.fastq.gz}"
  sample=$(basename "$f1" _1_trimmed.fastq.gz)

  echo "Processing sample: $sample"

  # Skip if assembly already completed
  if [ -f "$OUTPUT_BASE/${sample}_spades/contigs.fasta" ]; then
      echo "Skipping $sample because assembly already exists."
      continue
  fi

  # Run SPAdes
  spades.py \
    -1 "$f1" \
    -2 "$f2" \
    -o "$OUTPUT_BASE/${sample}_spades" \
    --threads "$THREADS" \
    --memory "$MEMORY"

  echo "Finished assembling $sample"
done

echo "All assemblies finished."



