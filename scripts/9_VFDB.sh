
#!/bin/bash
# Virulence factor detection with Abricate + VFDB

# Create output directory
mkdir -p abricate_vfdb

# Loop over all assemblies
for genome in rawdata_50/assembly/*/contigs.fasta; do
    sample=$(basename $(dirname "$genome"))
    abricate --db vfdb "$genome" > abricate_vfdb/${sample}_vfdb.tsv
done

# Make a summary table (TSV)
abricate --summary abricate_vfdb/*.tsv > abricate_vfdb/summary.tsv

# Convert TSV files to CSV
for file in abricate_vfdb/*.tsv; do
    sed 's/\t/,/g' "$file" > "${file%.tsv}.csv"
done

# Also convert summary to CSV
sed 's/\t/,/g' abricate_vfdb/summary.tsv > abricate_vfdb/summary.csv

