#!/usr/bin/env bash
set -euo pipefail


######################################
echo "Mapping haplotypes to breeds..."
######################################

LC_ALL=C \
awk '{
  match($2, /^[^#]+/)
  b=substr($2, RSTART, RLENGTH)

  if(b ~ /^NEL/) b="Nelore"
  else if(b ~ /^GIR/) b="Gyr"
  else if(b ~ /^GUZ/) b="Guzerat"
  else if(b ~ /^SIN/) b="Sindi"
  else if(b ~ /^TAB/) b="Tabapua"
  else b="OTHER"

  print $1 "\t" b
}' node_path_pairs_noREF.tsv | sort -u --parallel=100 -S 50% | awk '{breeds[$1]=breeds[$1]","$2
}
END{
  for(n in breeds){
    sub(/^,/, "", breeds[n])
    print n"\t"breeds[n]
  }
}' > node_breeds.tsv


#################################
echo "Building boolean matrix..."
#################################

awk '
BEGIN{
    FS="\t"; OFS="\t"
    breeds[1]="Nelore"
    breeds[2]="Gyr"
    breeds[3]="Guzerat"
    breeds[4]="Sindi"
    breeds[5]="Tabapua"

    printf "node"
    for(i=1;i<=5;i++) printf OFS breeds[i]
    printf "\n"
}

{
    gsub(/ /,"",$2)   # remove espacos
    split($2, arr, ",")

    delete present
    for(i in arr) present[arr[i]]=1

    printf $1
    for(i=1;i<=5;i++){
        printf OFS ((breeds[i] in present)?1:0)
    }
    printf "\n"
}
' node_breeds.tsv > boolean_matrix.tsv


###################################
echo "Aggregating intersections..."
###################################

awk '
NR==FNR{
    len[$1]=$2
    next
}

{
    node=$1
    if(node in ref) next

    split($2,a,",")
    delete seen

    key=""
    for(i in a){
        if(a[i]=="" || seen[a[i]]) continue
        seen[a[i]]=1
        key=key","a[i]
    }

    sub(/^,/,"",key)

    count[key]++
    len[key]+=len[node]
}

END{
    print "group\tnodes\tlength_bp"
    for(k in count)
        print k"\t"count[k]"\t"len[k]
}
' node_length.tsv node_breeds.tsv > breed_intersections.tsv


echo "Done."