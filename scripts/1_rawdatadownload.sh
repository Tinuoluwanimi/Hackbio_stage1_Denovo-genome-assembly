#!/bin/bash
# Create directory for the 50 samples
mkdir rawdata_50
# Change into that directory
cd rawdata_50
# Download the original 100 sample script
wget https://raw.githubusercontent.com/HackBio-Internship/2025_project_collection/refs/heads/main/SA_Polony_100_download.sh
# Run only the first 100 lines (50 samples with 2 paired-end reads each)
head -n 100 SA_Polony_100_download.sh | bash

