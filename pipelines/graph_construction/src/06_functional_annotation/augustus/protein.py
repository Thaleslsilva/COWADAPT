import re

proteins = {}
current_gene = None
collecting = False
seq = ""

with open("augustus_out/nruis_with_protein.gff3") as f:
    for line in f:
        
        if line.startswith("# start gene"):
            current_gene = line.strip().split()[-1]
        
        elif "# protein sequence" in line:
            collecting = True
            seq = ""
            line = line.split("[",1)[1]
        
        elif collecting:
            line = line.strip()
            
            if "]" in line:
                seq += line.replace("]", "").replace("#","").strip()
                proteins[current_gene] = seq
                collecting = False
            else:
                seq += line.replace("#","").strip()

# save fasta
with open("augustus_proteins.faa", "w") as out:
    for gid, seq in proteins.items():
        out.write(f">{gid}\n{seq}\n")