
#!/bin/bash
# Comprehensive AMR detection with multiple databases

# Create output directories
mkdir -p abricate_results/card
mkdir -p abricate_results/resfinder
mkdir -p abricate_results/ncbi

# Loop over all assemblies
for genome in rawdata_50/assembly/*/contigs.fasta; do
    sample=$(basename $(dirname $genome))
    echo "Processing: $sample"
    
    # Run Abricate with multiple databases
    abricate --db card "$genome" > abricate_results/card/${sample}_card.txt
    abricate --db resfinder "$genome" > abricate_results/resfinder/${sample}_resfinder.txt
    abricate --db ncbi "$genome" > abricate_results/ncbi/${sample}_ncbi.txt
done

# Create individual summary tables
abricate --summary abricate_results/card/*.txt > abricate_card_summary.tsv
abricate --summary abricate_results/resfinder/*.txt > abricate_resfinder_summary.tsv
abricate --summary abricate_results/ncbi/*.txt > abricate_ncbi_summary.tsv

# Create a combined summary of all databases
abricate --summary abricate_results/*/*.txt > abricate_combined_summary.tsv

echo "Multi-database analysis complete!"
echo "Individual summaries: abricate_*_summary.tsv"
echo "Combined summary: abricate_combined_summary.tsv"
