#!/bin/bash

set -euo pipefail

echo "##########################################################################"
echo "# Mode 2 - Prediction in parallel windows (for large datasets)...         "
echo "##########################################################################"
echo ""

# Augustus ships with a script for windowed parallelization
# Locate the script
find $(dirname $(which augustus)) -name "augustus_parallel*" 2>/dev/null
find / -name "splitMfasta.pl" 2>/dev/null

# Recommended method: split the FASTA and run in parallel
# Step 1: split into 1 Mb chunks
python3 - <<'EOF'
from Bio import SeqIO
import os

os.makedirs("augustus_chunks", exist_ok=True)
chunk_size = 1_000_000  # 1 Mb per chunk

chunk_id = 0
current_size = 0
current_records = []

for rec in SeqIO.parse("nruis_softmasked.fasta", "fasta"):
    current_records.append(rec)
    current_size += len(rec.seq)

    if current_size >= chunk_size:
        outfile = f"augustus_chunks/chunk_{chunk_id:04d}.fasta"
        SeqIO.write(current_records, outfile, "fasta")
        print(f"Chunk {chunk_id}: {len(current_records)} seqs, "
              f"{current_size/1e6:.2f} Mb -> {outfile}")
        chunk_id += 1
        current_records = []
        current_size = 0

# Last chunk
if current_records:
    outfile = f"augustus_chunks/chunk_{chunk_id:04d}.fasta"
    SeqIO.write(current_records, outfile, "fasta")
    print(f"Chunk {chunk_id}: {len(current_records)} seqs, "
          f"{current_size/1e6:.2f} Mb -> {outfile}")

print(f"\nTotal chunks: {chunk_id + 1}")
EOF

# Step 2: create the submission script for the cluster (SLURM)
cat > run_augustus_array.sh << 'SLURM'
#!/bin/bash
#SBATCH --job-name=augustus_nruis
#SBATCH --array=0-99%20        # adjust to the number of chunks
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --output=logs/augustus_%A_%a.out

CHUNK=$(printf "augustus_chunks/chunk_%04d.fasta" $SLURM_ARRAY_TASK_ID)

if [ ! -f "$CHUNK" ]; then
    echo "Chunk $CHUNK not found, skipping"
    exit 0
fi

augustus \
    --species=Bos_taurus_refseq \
    --softmasking=1 \
    --gff3=on \
    --stopCodonExcludedFromCDS=false \
    --min_intron_len=50 \
    --UTR=off \
    --outfile=augustus_out/chunk_$(printf "%04d" $SLURM_ARRAY_TASK_ID).gff3 \
    "$CHUNK"
SLURM

mkdir -p logs
sbatch run_augustus_array.sh


### Concatenate and process the results

# Concatenate all GFF3 files (remove duplicate headers)
cat augustus_out/chunk_*.gff3 | \
    grep -v "^#" | \
    grep -v "^$" \
    > augustus_out/all_predictions_raw.gff3

# Add a clean header
echo "##gff-version 3" | \
    cat - augustus_out/all_predictions_raw.gff3 \
    > augustus_out/nruis_augustus_combined.gff3

# Check the basic result
grep -c "	gene	" augustus_out/nruis_augustus_combined.gff3
grep -c "	mRNA	" augustus_out/nruis_augustus_combined.gff3
grep -c "	CDS	" augustus_out/nruis_augustus_combined.gff3
