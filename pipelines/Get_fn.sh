#!/bin/bash

######################################################################################
###
###                             COWADAPT PROJECT
### Retrieve decrypted fastq files from each folder and compress with gzip
###
### v.24.10.25                                                   Thales de Lima Silva
###
######################################################################################

# Define the root folder where directories are located
root_folder="~/cowadapt_fq/"

# Define the output file
output_file="file_list.txt"

# Clear the output file if it already exists
> "$output_file"

# Access each directory within the root folder
for dir in "$root_folder"/*/; do
    # Remove trailing slash from directory name for display
    dir_name=$(basename "$dir")

    # Write directory name to output file
    echo "Directory: $dir_name" >> "$output_file"

    # List files in current directory
    for file in "$dir"*; do
        # Verify it is a file (ignore subdirectories)
        if [ -f "$file" ]; then
            # Write file name to output file
            echo "  $(basename "$file")" >> "$output_file"
            # Compress file with gzip
            new_name="$file.gz"
            pigz -p 50 -c "$file" > "$new_name"
            echo "File $file compressed to $new_name"
            echo ""
            # Move fastq files to root folder
            mv "$new_name" "$root_folder"
        fi
    done

    # Add blank line to separate entries
    echo "" >> "$output_file"
done

echo "File list generated in $output_file"
