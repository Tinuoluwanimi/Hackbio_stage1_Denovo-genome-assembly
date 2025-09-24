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

