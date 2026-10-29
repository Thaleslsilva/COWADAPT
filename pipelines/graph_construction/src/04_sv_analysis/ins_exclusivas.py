import pysam
import pandas as pd

# --- Load input data ---
vcf_file = "../snmk_out/SV.vcf.gz"
matrix_file = "Indicine_Breed_Presence_Matrix.tsv"

df = pd.read_csv(matrix_file, index_col=0)

# List of breeds (columns of the matrix)
breeds = df.columns.tolist()

# --- Extract exclusive variants per breed ---
# Dictionary to store variant sets per breed
breed_variant_sets = {}

for breed in breeds:
    df_only = df[
        (df[breed] == True) &
        (df.drop(columns=[breed]).sum(axis=1) == 0)
    ]
    
    # Store variant IDs (index = "chr:pos")
    breed_variant_sets[breed] = set(df_only.index)

# --- Open VCF ---
vcf = pysam.VariantFile(vcf_file)

# --- Initialize results dictionary ---
results = {}

for breed in breeds:
    results[breed] = {
        "ins_count": 0,
        "ins_total_length": 0
    }

# --- Iterate over VCF records once (efficient approach) ---
for record in vcf:
    var_id = f"{record.chrom}:{record.pos}"

    ref_len = len(record.ref)

    # Loop over ALT alleles
    for alt in record.alts:
        alt_len = len(alt)

        # Check if this is an insertion (sequence-based definition)
        if alt_len > ref_len:
            ins_size = alt_len - ref_len

            # Assign this variant to the correct breed(s)
            for breed in breeds:
                if var_id in breed_variant_sets[breed]:
                    results[breed]["ins_count"] += 1
                    results[breed]["ins_total_length"] += ins_size

# --- Print results ---
for breed in breeds:
    print(f"Breed: {breed}")
    print(f"  Number of insertions: {results[breed]['ins_count']}")
    print(f"  Total insertion length (bp): {results[breed]['ins_total_length']}")
    print("-" * 40)