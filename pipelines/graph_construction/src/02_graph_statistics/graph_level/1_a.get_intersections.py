### Command
# python scripts/get_intersections.py IND_pangenome_final.gfa ARS_UCD2


import sys
import gzip
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

from config_loader import load_config

def parse_gfa(gfa_file, ref_prefix, samples):
    opener = gzip.open if gfa_file.endswith(".gz") else open

    sample_index = {s:i for i,s in enumerate(samples)}
    REF_BIT = 1 << len(samples)

    node_lengths = {}
    node_mask = defaultdict(int)

    with opener(gfa_file, "rt") as f:
        for line in f:
            if line[0] == "S":
                parts = line.split('\t')
                node_lengths[parts[1]] = len(parts[2])

            elif line[0] == "W":
                parts = line.split('\t')
                sample = parts[1]

                if sample != ref_prefix and sample not in sample_index:
                    continue

                nodes = parts[6].replace('>', ' ').replace('<', ' ').split()

                if sample == ref_prefix:
                    bit = REF_BIT
                else:
                    bit = 1 << sample_index[sample]

                for n in nodes:
                    node_mask[n] |= bit

            elif line[0] == "P":
                parts = line.split('\t')
                sample = parts[1].split('#')[0]

                if sample != ref_prefix and sample not in sample_index:
                    continue

                nodes = parts[2].replace('+','').replace('-','').split(',')

                if sample == ref_prefix:
                    bit = REF_BIT
                else:
                    bit = 1 << sample_index[sample]

                for n in nodes:
                    node_mask[n] |= bit

    return node_lengths, node_mask, sample_index, REF_BIT


def process_chunk(chunk, node_lengths, REF_BIT):
    result = defaultdict(lambda: [0,0])

    for node, mask in chunk:
        if mask & REF_BIT:
            continue

        if mask == 0:
            continue

        length = node_lengths.get(node,0)

        result[mask][0] += 1
        result[mask][1] += length

    return result


def merge_dicts(dicts):
    final = defaultdict(lambda:[0,0])
    for d in dicts:
        for k,v in d.items():
            final[k][0]+=v[0]
            final[k][1]+=v[1]
    return final


def decode_mask(mask, sample_index):
    names=[]
    for s,i in sample_index.items():
        if mask & (1<<i):
            names.append(s)
    return ",".join(sorted(names))


def get_intersections(gfa_file, ref_prefix, samples, threads=8):

    print("Parsing GFA...")
    node_lengths, node_mask, sample_index, REF_BIT = parse_gfa(
        gfa_file, ref_prefix, samples
    )

    items = list(node_mask.items())
    chunk_size = len(items)//threads + 1
    chunks = [items[i:i+chunk_size] for i in range(0,len(items),chunk_size)]

    print("Computing intersections in parallel...")

    with ThreadPoolExecutor(max_workers=threads) as exe:
        results = list(
            exe.map(
                process_chunk,
                chunks,
                [node_lengths]*len(chunks),
                [REF_BIT]*len(chunks)
            )
        )

    intersection_map = merge_dicts(results)

    print("Writing TSV...")

    with open("intersections.tsv","w") as out:
        out.write("samples\tnodes\tlength_mb\n")

        for mask,stats in sorted(
            intersection_map.items(),
            key=lambda x:(bin(x[0]).count("1"),x[0]),
            reverse=True
        ):
            names = decode_mask(mask,sample_index)
            bp = stats[1]
            out.write(f"{names}\t{stats[0]}\t{bp:.0f}\n")


if __name__ == "__main__":

    samples = load_config()["SAMPLES"]

    if len(sys.argv) < 3:
        print("Usage: python script.py graph.gfa REF")
        sys.exit()

    get_intersections(
        sys.argv[1],
        sys.argv[2],
        samples,
        threads=100
    )