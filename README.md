**Genomic Investigation of the 2017-2018 South African Listeriosis Outbreak**

**Introduction**

In early 2017, South Africa faced a public health crisis that would become the world's largest recorded outbreak of listeriosis. The outbreak resulted in 978 laboratory-confirmed cases with 183 deaths—a devastating 27% case fatality rate. Vulnerable groups including neonates, pregnant women, the elderly, and immunocompromised patients were disproportionately affected. Epidemiological investigations pointed to processed cold meats, particularly polony from the Enterprise Foods facility in Polokwane, as the likely source.

This project utilizes whole-genome sequencing and de novo genome assembly to analyze bacterial isolates from the outbreak, aiming to confirm pathogen identity, characterize antimicrobial resistance profiles, and identify virulence factors that contributed to the high mortality rate. The answer lies in the power of whole-genome sequencing (WGS), a tool that can unlock the genetic secrets of these deadly bacteria.

**Methods**
**Download raw sequencing data**
```
#!/bin/bash
# Create directory for the 50 samples
mkdir rawdata_50
# Change into that directory
cd rawdata_50
# Download the original 100 sample script
wget https://raw.githubusercontent.com/HackBio-Internship/2025_project_collection/refs/heads/main/SA_Polony_100_download.sh
# Run only the first 100 lines (50 samples with 2 paired-end reads each)
head -n 100 SA_Polony_100_download.sh | bash
 ```
**Quality Control and Trimming.**

Raw sequencing reads underwent initial quality assessment using FastQC to evaluate base quality, adapter content, and sequence duplication.
```
#!/bin/bash
# Quality control on raw reads
# Directories
RAW_DIR="rawdata_50"             # folder with raw .fastq.gz files
QC_DIR="$RAW_DIR/qc_report"      # output folder for QC reports

# Create QC directory if it doesn't exist
mkdir -p "$QC_DIR"

# Run FastQC on all raw reads
fastqc "$RAW_DIR"/*.fastq.gz -o "$QC_DIR"
```
**MultiQC was used to aggregate results from multiple samples for comparative analysis.**

```multiqc "$QC_DIR" -o "$QC_DIR/multiqc_report" ```

**Trimming was performed to remove adapters and low-quality sequences.**

```
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

multiqc "$TRIM_DIR" -o "$TRIM_DIR/multiqctrimmed_report"
 ```
**De Novo Genome Assembly**
Quality-trimmed reads were assembled using SPAdes genome assembler.
 ```
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
 ```

**Assembly Quality Assessment**
Assembly quality was evaluated using QUAST to assess contiguity and completeness metrics.
 ```
#!/bin/bash
# Assessing assembly with Quast.Py
mkdir -p  quast_report
for sample in rawdata_50/assembly/*spades ;do
    contigs="$sample/contigs.fasta"
    if [ -s "$contigs" ]; then  # only run QUAST if contigs.fasta exists and is not empty
        sample_name=$(basename "$sample")
        echo "Running QUAST on $sample_name ..."
        quast.py "$contigs" -o "quast_report/${sample_name}"
    else
        echo "Skipping $sample (file is empty)"
    fi
done
 ```
**Taxonomic Identification**
Created a 16S rRNA reference database and compared the assembled contigs to it using BLAST to identify the bacterial species.
 ```
#!/bin/bash
# Download and build 16S database
mkdir -p 16S_db
# Download Listeria 16S rRNA sequences from NCBI
echo " Downloading Listeria 16S sequences..."
esearch -db nucleotide -query "Listeria[Organism] AND 16S ribosomal RNA" \
  | efetch -format fasta > 16S_db/listeria_16S.fasta

# Check if download succeeded
if [[ ! -s 16S_db/listeria_16S.fasta ]]; then
    echo " Error: download failed or empty file."
    exit 1
fi
echo " Downloaded: 16S_db/listeria_16S.fasta"
# Build BLAST DB
echo " Building BLAST database..."
makeblastdb -in 16S_db/listeria_16S.fasta -dbtype nucl -out 16S_db/listeria_16S
echo " BLAST DB ready: 16S_db/listeria_16S"

 ```
 ```
#!/bin/bash
# Extract 16S rRNA genes from SPAdes contigs and BLAST them against a custom 16S database
# Directories
ASSEMBLY_DIR="./assembly"               # Input: SPAdes outputs (assembly/*_spades/contigs.fasta)
EXTRACTED_16S_DIR="./extracted_16s"     # Output: extracted 16S sequences
BLAST_RESULTS_DIR="./blast_16s_results" # Output: BLAST results
DB_16S="./16S_db/listeria_16S"          # Your local BLAST DB (built beforehand)

# Create output directories
mkdir -p "$EXTRACTED_16S_DIR" "$BLAST_RESULTS_DIR"
# Loop through all SPAdes assemblies
for sample_dir in "$ASSEMBLY_DIR"/*_spades; do
    contigs="$sample_dir/contigs.fasta"
    sample_name=$(basename "$sample_dir")

    echo "Processing: $sample_name"

    # Extract 16S rRNA sequences with barrnap
    extracted="$EXTRACTED_16S_DIR/${sample_name}_16S.fasta"
    barrnap --kingdom bac --outseq "$extracted" "$contigs" 2>/dev/null

    # Skip if no 16S genes found
    if [[ ! -s "$extracted" ]]; then
        echo " No 16S rRNA genes for $sample_name"
        continue
    fi
    # Run BLASTn on extracted sequences
    blast_out="$BLAST_RESULTS_DIR/${sample_name}_16S_blast.tsv"
    blastn -query "$extracted" \
           -db "$DB_16S" \
           -out "$blast_out" \
           -outfmt "6 qseqid sseqid pident length evalue bitscore stitle" \
           -max_target_seqs 5

    echo " BLAST complete for $sample_name "
done
echo "finally done."
 ```

Antimicrobial Resistance and Virulence Gene Detection
ABRicate was used to screen contigs for AMR genes and virulence factors against CARD and VFDB databases.
 ```
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

 ```
 ```
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

 ```

**Results and Discussion**

**Quality Control and Trimming Efficiency**

MultiQC analysis revealed significant improvements in read quality after trimming. The pre-trimming analysis showed variable quality with duplication rates ranging from 17.4% to 40.6% and GC content of 40-41% across samples. Post-trimming results demonstrated:

•	Sequence Duplication: Dramatically reduced to 0.1-3.0% 

•	Reads After Filtering: Increased from 0.5-1.1M to 0.9-2.2M reads per sample

•	GC Content: Maintained stability at 40.8-42.2%, consistent with Listeria characteristics

•	Adapter Content: Reduced to 3.3-12.2% residual levels

This quality improvement was crucial for reliable genome assembly, as high duplication rates can lead to assembly artifacts and misrepresentations of genomic content.

Genome Assembly Quality Assessment

QUAST analysis revealed high-quality genome assemblies across all isolates:

**Key Assembly Statistics:**

•	Total length: ~3.01 Mbp (consistent with L. monocytogenes genome size)

•	N50 values: 56,120 - 191,091 bp (indicating good assembly continuity)

•	Number of contigs: 40-160 contigs per assembly (after filtering ≥500 bp)

•	Largest contig: 186,495 - 378,598 bp

•	GC content: 37.84-38.04% (typical for Listeria species)

N's per 100 kbp: 0 (no ambiguous bases)


**Assembly Performance Highlights:**

•	Best assembly: SRR27013330 (N50: 191,091 bp, 46 contigs)

•	Consistent quality: All assemblies achieved complete genome coverage (~3.01 Mbp)

•	Reliable gene detection: N50 values >50,000 bp ensure accurate AMR and virulence gene calling

The high assembly quality provides confidence in downstream analyses, with contiguity metrics supporting reliable gene annotation and variant detection.

**Organism Identification**

BLAST analysis confirmed the pathogen as Listeria monocytogenes with high confidence across all isolates. The consistent genomic features including GC content and genome size provided additional confirmation of species identity.

**Antimicrobial Resistance Profile**

ABRicate analysis against the CARD database revealed a conserved and concerning AMR profile:

**AMR Genes Identified with 100% Prevalence:**

•	FosX (100% identity): Confers resistance to fosfomycin, a broad-spectrum antibiotic

•	lin (100% identity): Provides resistance to lincosamides including clindamycin and lincomycin

•	norB (100% identity): Confers resistance to fluoroquinolones such as norfloxacin and ciprofloxacin

•	Listeria_monocytogenes_mprF (100% identity): Intrinsic resistance to cationic antimicrobial peptides

**Clinical Implications:**

•	Fluoroquinolones ineffective: norB gene suggests resistance to ciprofloxacin, a common empiric choice

•	Lincosamide limitation: lin gene eliminates clindamycin as an alternative for penicillin-allergic patients

•	Fosfomycin resistance: Particularly concerning for multi-drug resistant infection management

**Virulence Factors and Toxin Genes**

Comprehensive VFDB analysis identified an extensive virulence arsenal explaining the high mortality rate:

K**ey Virulence Factors Detected:**

•	hly (Listeriolysin O): 100% identity - Pore-forming toxin essential for vacuole escape and cell lysis

•	plcA/plcB: 99.89-100% identity - Phospholipases that degrade host cell membranes

•	actA: 99.9% identity - Enables actin-based motility for cell-to-cell spread

•	inlA/inlB: 99.63-100% identity - Host cell invasion proteins

•	prfA: 100% identity - Master regulator of virulence gene expression

**Treatment Recommendations**

•	Ampicillin + Gentamicin (synergistic combination)

•	High-dose Penicillin G

•	Trimethoprim-sulfamethoxazole for penicillin-allergic patients

**Conclusion**

This study shows how scientists use whole-genome sequencing (WGS) to respond to public health outbreaks efficiently and accurately. By analyzing the outbreak isolates, they confirmed the pathogen was Listeria monocytogenes and identified genes that make it resistant to certain antibiotics. This information helps healthcare professionals choose effective treatments and avoid ineffective ones.

WGS also provides a clear genetic picture of the outbreak strain, helping public health teams understand how it spreads, why it’s dangerous, and how to prevent future outbreaks. In short, WGS gives essential insights that guide treatment decisions, inform public health strategies, and reduce the impact of outbreaks.
Raw Sequencing Data

The raw sequencing reads analyzed in this project can be accessed here https://raw.githubusercontent.com/HackBio-Internship/2025_project_collection/refs/heads/main/SA_Polony_100_download.sh


