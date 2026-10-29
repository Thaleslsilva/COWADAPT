#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#==================================================
# Total graph size, sequence belonging to the reference, and novel sequence
#==================================================

awk '
$1=="S"{
    total+=length($3)
    if($0 ~ /SN:Z:ARS_UCD2/) ref+=length($3)
}
END{
    print "Graph:",total
    print "Reference:",ref
    print "Novel sequence:",total-ref
}' IND_pangenome_final.gfa


#==================================================
# Total node count, reference nodes, and non-reference nodes
#==================================================

awk '
$1=="S"{
    total++
    if($0 ~ /SN:Z:ARS_UCD2/) ref++
}
END{
    nonref=total-ref
    print "Total nodes:",total
    print "Reference nodes:",ref
    print "Non-reference nodes:",nonref
}' IND_pangenome_final.gfa


#==================================================
# Count and length of non-reference nodes
#==================================================

# Getting intersections of samples
python "$SCRIPT_DIR/1_a.get_intersections.py" IND_pangenome_final.gfa ARS_UCD2

# Getting Nelore-only intersections
python "$SCRIPT_DIR/1_b.get_true_nelore_intersections.py" IND_pangenome_final.gfa ARS_UCD2

# Checking total nodes, nodes in reference path, novel nodes and novel sequence relative to reference
python "$SCRIPT_DIR/1_c.graph_novel_sequence.py" IND_pangenome_final.gfa ARS_UCD2

# Assembly sharing nodes
python "$SCRIPT_DIR/1_d.get_assembly_nonref.py" IND_pangenome_final.gfa ARS_UCD2 NEL_017

# Assembly-specific nodes (for each sample)
python "$SCRIPT_DIR/1_e.get_assmPriv_nonref_v2.py" IND_pangenome_final.gfa ARS_UCD2 GUZ_hap IND_analysis/GUZ.bed

# Sharing nodes of Nelore
# NOTE: get_nel_v2.sh is not included in this repository.
#bash scripts/get_nel_v2.sh IND_analysis/ODGI/IND_pangenome_final.og ARS_UCD IND_stats/nelore_intersections.tsv



