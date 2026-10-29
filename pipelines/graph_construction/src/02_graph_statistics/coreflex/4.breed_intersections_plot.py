import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter
from matplotlib.ticker import FuncFormatter
from upsetplot import UpSet
import warnings

warnings.filterwarnings("ignore", category=FutureWarning)

# --- Configuration ---
# Control variables for easy editing
font_size_labels = 12      # Labels for assemblies
font_size_counts = 10      # Numbers on top of bars
bar_color_vert = "#71967F" # green
bar_color_side = "#71967F"                  # orange 967F71
matrix_dot_color = "#969271" # yellow     # purple 927196

# --- Data Loading (Optimized) ---
# Load boolean matrix
df = pd.read_csv("boolean_matrix.tsv", sep="\t")

# --- Processing ---
# Define columns (breeds)
breeds = ["Nelore","Gyr","Guzerat","Sindi","Tabapua"]

# Ensure they are integers (0/1)
df[breeds] = df[breeds].astype(int)

# Group by count (nodes by intersection)
grouped = df.groupby(breeds).size() / 1e6


#######################################
### UpSet Plot - Shared non-ref alleles
#######################################

print("Generating customized plot...")

# Configuration for Proportions and Aesthetics
up = UpSet(
    grouped,
    show_counts='%.3f',
    sort_by="cardinality",
    intersection_plot_elements=20,   # Height of the top bars (Default = 3).
    totals_plot_elements=5,          # Width of the side bars (Default = 2).
    element_size=40,                 # Increase this to make the matrix larger relative to bars
    
)

# Set Figure size (Width, Height)
fig = plt.figure(figsize=(18, 14))
axes = up.plot(fig=fig)


# --- Fine-Tuning the Appearance ---

bar_color_intersections = "#2F4F4F" # Dark Slate Gray for top bars
bar_color_side = "#2ca02c"          # SteelBlue for side bars
bar_color_edge = "#2ca02c"          # Black edges
matrix_dot_active = "#71967F"       # COWADAPT Green
matrix_dot_inactive = "#E0E0E0"     # Light gray for empty intersections
matrix_line_color = "#000000"       # Darker green for connecting lines
text_color = "#333333"              # Dark gray for text

# Formatting Axis - NO Scientific Notation
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
        ax.set_ylabel("Shared non-ref segment counts (Mi)", fontsize=24)

    # Customizing the intersection top bars (patches)
        for patch in ax.patches:
            patch.set_facecolor(bar_color_side)
            patch.set_edgecolor(bar_color_edge)
            patch.set_linewidth(1.2)       # Border thickness
            patch.set_alpha(0.9)           # Transparency (0.0 to 1.0)
            # Hatching patterns: '/', '\', '|', '-', '+', 'x', 'o', 'O', '.', '*'
            patch.set_hatch('')            
            patch.set_zorder(3)            # Bring bars to the front of the grid
    else:
        ax.xaxis.set_major_formatter(formatter)
        ax.set_xlabel("Non-ref segments (Mi)", fontsize=18, color=text_color)


# 5.2. Customizing Sidebar Colors
for text in axes['totals'].texts:
    text.set_visible(True)

for patch in axes['totals'].patches:
    patch.set_facecolor("#000000")
    patch.set_edgecolor("#000000")
    patch.set_linewidth(1.0)
    patch.set_alpha(0.85)
    # patch.set_hatch('//') # Uncomment to add hatching to side bars


# 5.3. Rotating and Scaling Top Labels (Counts)
for text in axes['intersections'].texts:
    text.set_fontsize(18)
    text.set_rotation(90)
    text.set_color(text_color)
    text.set_fontweight('normal')    # Options: 'normal', 'bold', 'heavy', 'light', or numeric (e.g., 700)
    text.set_fontstyle('normal')     # Options: 'normal', 'italic', 'oblique'
    text.set_ha('center')            # Horizontal alignment: 'center', 'right', 'left'
    # text.set_va('bottom')          # Vertical alignment: 'center', 'top', 'bottom', 'baseline'
    

# 5.4. Customizing the Matrix (Dots and Lines)
# We target only the foreground dots (active intersections) and the connectors
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
    line.set_color(matrix_line_color)
    line.set_linewidth(0.5)
    line.set_linestyle('-')  # Options: '-' (solid), '--' (dashed), '-.' (dash-dot), ':' (dotted)
    line.set_alpha(0.9)
    line.set_zorder(1)       # Keep lines behind the active dots

# 5.5. Font sizes for tick labels
axes['matrix'].tick_params(axis='y', labelsize=18, labelcolor='black', width=1.5, length=6)
axes['intersections'].tick_params(axis='y', labelsize=16, colors='black', direction='out')
axes['totals'].tick_params(axis='x', labelsize=12, rotation=0)

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


plt.savefig("upset_plot.png", bbox_inches='tight', dpi=600)
plt.close()
print(f"Plot successfully saved!")


############################################
### Bar Plot - Shared non-ref allele lengths
############################################

### Load data
df = pd.read_csv("breed_intersections.tsv", sep="\t")

### Convert to Mb
df["length_mb"] = df["length_bp"] / 1e6

# Sort
df = df.sort_values("length_mb", ascending=True)

fig, ax = plt.subplots(figsize=(7,10))

bars = ax.barh(
    df["group"],
    df["length_mb"],
    color="#1f77b4",     
    edgecolor="black",
    linewidth=0.4
)

# Labels (1 decimal place, offset to the right)
for i, v in enumerate(df["length_mb"]):
    ax.text(
        v + df["length_mb"].max()*0.02,   # small offset (like hjust=-0.2)
        i,
        f"{v:.1f}",
        va="center",
        fontsize=14
    )

# X axis (equivalent to scale_y_continuous in coord_flip)
ax.set_xlim(0, df["length_mb"].max() * 1.2)

# Labels
ax.set_xlabel("Shared non-ref segment lengths (Mb)", fontsize=20)
ax.xaxis.set_label_coords(0.1, -0.03)
ax.set_ylabel("Indicine breeds", fontsize=20)

# Reduce the Y axis label size
ax.tick_params(axis='x', labelsize=12)
ax.tick_params(axis='y', labelsize=14)

# Remove extra margins and leave room for the labels
plt.subplots_adjust(right=0.85)

ax.margins(y=0.01)

plt.tight_layout()
plt.savefig("nonref_share_length.png", dpi=600)
