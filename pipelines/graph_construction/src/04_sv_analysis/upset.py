# ============================================================
# VCF to Breed-Level Boolean Matrix (NumPy 2.0 Compatible)
# Project: COWADAPT - Indicine Pangenome Analysis
# Description: Generates an UpSet plot for Breed-specific SVs
# Author: COWADAPT Senior Research Assistant
# ============================================================

import pysam
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.ticker import ScalarFormatter  # FIXED: Required for axis formatting
from upsetplot import from_indicators, UpSet
import warnings

warnings.filterwarnings("ignore", category=FutureWarning)

def run_upset_pipeline(vcf_input, tsv_output, plot_output):
    # --- 0. Plot Aesthetics Configuration ---
    # Defining variables that were missing in the original snippet
    bar_color_side = "#4682B4"      # SteelBlue for horizontal bars
    matrix_dot_color = "#A02C2C"    # COWADAPT Green
    font_size_counts = 9

    # 1. Initialize VCF reader and Sample Mapping
    print(f"Reading VCF: {vcf_input}")
    vcf = pysam.VariantFile(vcf_input)
    samples = list(vcf.header.samples)
    
    # Breed mapping for Indicine pangenome (Nelore, Gyr, Guzerat, Sindi, Tabapua)
    breed_map = {
        'NEL': 'Nelore',
        'GIR': 'Gyr',
        'GUZ': 'Guzerat',
        'SIN': 'Sindi',
        'TAB': 'Tabapua'
    }
    
    sample_to_breed = {}
    for s in samples:
        matched = False
        for prefix, breed in breed_map.items():
            if s.startswith(prefix):
                sample_to_breed[s] = breed
                matched = True
                break
        if not matched:
            sample_to_breed[s] = 'Other'

    unique_breeds = list(breed_map.values())
    
    # 2. Extract presence/absence data
    variant_rows = []
    variant_ids = []

    print("Processing variants and aggregating by breed...")
    for record in vcf:
        breed_status = {breed: False for breed in unique_breeds}
        
        for sample_name, sample_data in record.samples.items():
            breed = sample_to_breed.get(sample_name, 'Other')
            if breed == 'Other':
                continue
            
            gt = sample_data['GT']
            if gt is not None:
                # Logic: True if any allele is non-reference (> 0)
                if any(allele is not None and allele > 0 for allele in gt):
                    breed_status[breed] = True
        
        variant_rows.append([breed_status[b] for b in unique_breeds])
        variant_ids.append(f"{record.chrom}:{record.pos}")

    # 3. Create Breed-Level Boolean DataFrame
    df_breed = pd.DataFrame(variant_rows, columns=unique_breeds, index=variant_ids)
    
    # 4. Save Boolean Matrix
    print(f"Saving breed-level boolean matrix to {tsv_output}...")
    df_breed.to_csv(tsv_output)

    # 5. Prepare and Generate UpSet Plot
    print("Preparing UpSet plot data...")
    upset_data = from_indicators(unique_breeds, data=df_breed)
    
    up = UpSet(
        upset_data,
        show_counts=True,
        sort_by="cardinality",
	    #facecolor="#FF5733",
	    intersection_plot_elements=7,    # Height of the top bars (Default = 3)
	    totals_plot_elements=5,          # Width of the side bars (Default = 2)
        element_size=40

    )

    fig = plt.figure(figsize=(18, 14))
    axes = up.plot(fig=fig)

    # --- 6. Fine-Tuning Appearance ---

    # Defining a robust color palette and style variables for COWADAPT reporting
    bar_color_intersections = "#d62728" # Dark Slate Gray for top bars
    bar_color_side = "#000000"          # SteelBlue for side bars
    bar_color_edge = "#000000"          # Black edges
    matrix_dot_active = "#71967F"       # COWADAPT Green
    matrix_dot_inactive = "#E0E0E0"     # Light gray for empty intersections
    matrix_line_color = "#000000"       # Darker green for connecting lines
    text_color = "#333333"              # Dark gray for text

    # 6.1. Formatting Axis - Removing Scientific Notation
    for ax_name in ['intersections', 'totals']:
        ax = axes[ax_name]
        formatter = ScalarFormatter()
        formatter.set_scientific(False)
        formatter.set_useOffset(False)
        
        # Adding background grid for better readability of large SV counts
        # Options: linestyle ('-', '--', '-.', ':'), alpha (0.0 to 1.0)
        ax.grid(True, axis='y' if ax_name == 'intersections' else 'x', 
                linestyle='--', alpha=0.4, color='gray', zorder=0)

        if ax_name == 'intersections':
            ax.yaxis.set_major_formatter(formatter)
            ax.set_ylabel("Shared variants", fontsize=20)

	    # Customizing the intersection top bars (patches)
            for patch in ax.patches:
                patch.set_facecolor(bar_color_intersections)
                patch.set_edgecolor(bar_color_intersections)
                patch.set_linewidth(1.2)       # Border thickness
                patch.set_alpha(0.9)           # Transparency (0.0 to 1.0)
                # Hatching patterns: '/', '\', '|', '-', '+', 'x', 'o', 'O', '.', '*'
                patch.set_hatch('')            
                patch.set_zorder(3)            # Bring bars to the front of the grid
        else:
            ax.xaxis.set_major_formatter(formatter)
            ax.set_xlabel("Total Variants", fontsize=20, color=text_color)

    # 6.2. Side Bars Color (Totals)
    for patch in axes['totals'].patches:
        patch.set_facecolor(bar_color_side)
        patch.set_edgecolor(bar_color_edge)
        patch.set_linewidth(1.0)
        patch.set_alpha(0.85)
        # patch.set_hatch('//') # Uncomment to add hatching to side bars

    # 6.3. Top Labels (Counts) Rotation
    for text in axes['intersections'].texts:
        text.set_fontsize(18)
        text.set_rotation(90)
        text.set_color(text_color)
        text.set_fontweight('normal')      # Options: 'normal', 'bold', 'heavy', 'light', or numeric (e.g., 700)
        text.set_fontstyle('normal')     # Options: 'normal', 'italic', 'oblique'
        # text.set_ha('center')          # Horizontal alignment: 'center', 'right', 'left'
        # text.set_va('bottom')          # Vertical alignment: 'center', 'top', 'bottom', 'baseline'

    # 6.4. Matrix Dots and Lines
    collections = axes['matrix'].collections

    # The UpSet plot creates PathCollections for the matrix dots.
    # collections[0] usually represents background/inactive dots.
    # collections[1] usually represents active dots in the intersection.
    if len(collections) >= 2:
        collections[1].set_facecolor(matrix_dot_inactive)
        collections[1].set_edgecolor("#000000")  # Outline color for active dots
        collections[1].set_linewidths(7.0)       # Outline thickness
        collections[1].set_alpha(1.0)
        # collections[1].set_sizes([250]) # Uncomment to make active dots larger than inactive ones
    
    # Connecting lines between active dots
    for line in axes['matrix'].lines:
        line.set_color("#FF890A")
        line.set_linewidth(0.5)
        line.set_linestyle('-')  # Options: '-' (solid), '--' (dashed), '-.' (dash-dot), ':' (dotted)
        line.set_alpha(0.9)
        line.set_zorder(1)       # Keep lines behind the active dots

    # 6.5. Ticks Adjustments
    axes['matrix'].tick_params(axis='y', labelsize=18, labelcolor='black', width=1.5, length=6)
    axes['intersections'].tick_params(axis='y', labelsize=16, colors='black', direction='out')
    axes['totals'].tick_params(axis='x', labelsize=12, rotation=45)

    # 6.6. Custom Matrix Background Shading (Restricted to Dots Area)
    ax_matrix = axes['matrix']
    
    # 1. Hide the default shading patches generated by upsetplot
    # We iterate over all patches in the matrix axis and make them invisible
    for patch in ax_matrix.patches:
        patch.set_visible(False)
    
    # 2. Draw our custom restricted shading
    # Get the exact X limits of the plotted intersection dots
    x_min, x_max = ax_matrix.get_xlim()
    
    # Loop over the y-axis (representing our Indicine breeds)
    num_breeds = len(unique_breeds)
    
    for y in range(num_breeds):
        # Apply shading only to alternating rows (even indices)
        if y % 2 == 0:
            # Create a rectangle strictly bounding the x_min and x_max
            # Y coordinate is centered on the breed index, so we start at y - 0.5
            rect = patches.Rectangle(
                (x_min, y - 0.5),      # (x, y) bottom-left corner
                x_max - x_min,         # Width: strictly limited to the dots area
                1.0,                   # Height: covers exactly one row
                facecolor="#F0F0F0",   # Soft gray shading for COWADAPT aesthetic
                edgecolor="none",      # No border
                alpha=0.8,             # Transparency
                zorder=0               # Strictly behind the dots and lines
            )
            ax_matrix.add_patch(rect)

    # Spines (borders of the subplots)
    for ax_name, ax in axes.items():
        if ax_name == 'matrix': 
            continue # The matrix usually looks better without a bounding box
        
        # Removing top and right borders for a cleaner, modern look
        ax.spines['bottom'].set_visible(True)
        ax.spines['right'].set_visible(False)
        
        # Thickening the remaining axes
        ax.spines['left'].set_linewidth(1.2)
        ax.spines['bottom'].set_linewidth(1.2)
        ax.spines['left'].set_color('#333333')
        ax.spines['bottom'].set_color('#333333')

    plt.savefig(plot_output, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"Workflow complete. Plot saved as {plot_output}")

if __name__ == "__main__":
    input_file = "../snmk_out/SV.vcf.gz"
    output_tsv = "Indicine_Breed_Presence_Matrix.tsv"
    output_png = "1UpSet_Indicine_Breeds.png"
    
    run_upset_pipeline(input_file, output_tsv, output_png)