#!/bin/bash
#
# Upload *.fasta.gz files to a Zenodo deposition bucket.
#
# Usage:
#   export ZENODO_TOKEN=...        # personal access token (never commit it)
#   export ZENODO_BUCKET_ID=...    # bucket id of the draft deposition
#   bash src/utils/up_Zenodo.sh <directory containing *.fasta.gz>

set -uo pipefail

: "${ZENODO_TOKEN:?Set ZENODO_TOKEN before running this script}"
: "${ZENODO_BUCKET_ID:?Set ZENODO_BUCKET_ID before running this script}"
UPLOAD_DIR="${1:?Usage: bash up_Zenodo.sh <directory containing *.fasta.gz>}"

echo ""

for f in "$UPLOAD_DIR"/*.fasta.gz; do
  filename=$(basename "$f")

  echo "$filename"
  echo ""

  attempt=1
  max_attempts=3

  until curl --fail --upload-file "$f" \
    -H "Authorization: Bearer $ZENODO_TOKEN" \
    --progress-bar \
    "https://zenodo.org/api/files/$ZENODO_BUCKET_ID/$filename"
  do
    echo "Attempt $attempt failed for $filename"
    attempt=$((attempt + 1))
    if [ $attempt -gt $max_attempts ]; then
      echo "Giving up on $filename after $max_attempts attempts" >> upload_errors.log
      break
    fi
    sleep 5
  done
done

echo ""
