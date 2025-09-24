#!/bin/bash
# BLASTn search for 16S sequences in SPAdes contigs using absolute paths
# Output will go to rawdata_50/blast_16s_results

# Directories
ASSEMBLY_DIR="/home/afolabi/Tinuoluwanimi/rawdata_50/assembly"        # SPAdes outputs (assembly/*_spades/contigs.fasta)
OUTPUT_DIR="/home/afolabi/Tinuoluwanimi/rawdata_50/blast_16s_results" # Output folder in same place as assembly
DB_16S="/home/afolabi/Tinuoluwanimi/rawdata_50/16S_db/listeria_16S"             # 16S BLAST database

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through all SPAdes assemblies
for sample_dir in "$ASSEMBLY_DIR"/*_spades; do
    [[ -d "$sample_dir" ]] || continue                       # skip if not a directory
    contigs="$sample_dir/contigs.fasta"
    [[ -f "$contigs" ]] || { echo "No contigs.fasta in $sample_dir"; continue; }

    sample_name=$(basename "$sample_dir")
    echo "Processing: $sample_name"

    # Run BLASTn directly on contigs
    blast_out="$OUTPUT_DIR/${sample_name}_16S_blast.tsv"
    blastn -query "$contigs" \
           -db "$DB_16S" \
           -out "$blast_out" \
           -outfmt "6 qseqid sseqid pident length evalue bitscore stitle" \
           -max_target_seqs 5

    echo "BLAST complete for $sample_name. Results saved to $blast_out"
done

echo "All samples processed ✅"

