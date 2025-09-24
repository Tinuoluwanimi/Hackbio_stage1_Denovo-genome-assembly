#!/bin/bash
# Trim read
RAW_DIR="rawdata_50"
TRIM_DIR="$RAW_DIR/trimmed_reads"
mkdir -p "$TRIM_DIR"

SAMPLES=($(ls "$RAW_DIR"/*_1.fastq.gz | xargs -n 1 basename | sed 's/_1.fastq.gz//'))

for SAMPLE in "${SAMPLES[@]}"; do
    R1="$RAW_DIR/${SAMPLE}_1.fastq.gz"
    R2="$RAW_DIR/${SAMPLE}_2.fastq.gz"

    # Skip sample if any file is missing
    if [[ ! -f "$R1" || ! -f "$R2" ]]; then
        echo "Skipping $SAMPLE: missing R1 or R2 file"
        continue
    fi

    fastp \
      -i "$R1" \
      -I "$R2" \
      -o "$TRIM_DIR/${SAMPLE}_1_trimmed.fastq.gz" \
      -O "$TRIM_DIR/${SAMPLE}_2_trimmed.fastq.gz" \
      --html "$TRIM_DIR/${SAMPLE}_fastp.html" \
      --json "$TRIM_DIR/${SAMPLE}_fastp.json"
done

multiqc "$TRIM_DIR" -o "$TRIM_DIR/multiqc_report"




