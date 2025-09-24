#!/bin/bash
# Quality control on raw reads
# Directories
RAW_DIR="rawdata_50"             # folder with raw .fastq.gz files
QC_DIR="$RAW_DIR/qc_report"      # output folder for QC reports

# Create QC directory if it doesn't exist
mkdir -p "$QC_DIR"

# Run FastQC on all raw reads
fastqc "$RAW_DIR"/*.fastq.gz -o "$QC_DIR"

# Run MultiQC to merge all FastQC reports
multiqc "$QC_DIR" -o "$QC_DIR/multiqc_report"



