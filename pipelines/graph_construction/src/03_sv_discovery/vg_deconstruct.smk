rule all:
    input:
        expand("{prefix}/Pangenome-out/final/{prefix}.SV.vcf", prefix=config["prefixes"]),
        expand("{prefix}/Pangenome-out/final/{prefix}.small.vcf", prefix=config["prefixes"])

# needs vg in PATH
# deconstructs the graph into a vcf file
# took approx 1 h for a graph with 4 Bos taurus assemblies on 12 threads
# -p <path to reference genome>; -a <all snarls>; -e is deprecated as it's now on default; -d is deprecated - ploidy now inferred from haplotypes in path names
# removed in shell command as it should not be necessary any more with latest vg version: sed $'s/\\t\\t/\\t.\\t/g;s/\\t$/\\t./g' > {output}
# overlaps do not need to be removed as they are already clipped in the minigraph-cactus pipeline
rule vg_deconstruct:
    input:
        lambda wildcards: f"{config['graph_path']}/{wildcards.prefix}_final.gfa"
    output:
        "{prefix}.raw.vcf"
    resources:
        cpus_per_task = config["deconstruction_cpu"],
        mem_mb_per_cpu = config["deconstruction_mem"],
        runtime = config["deconstruction_time"]
    params:
        ref = config["ref_ID"]
    shell:
        '''
        vg deconstruct -P {params.ref} -a -t {resources.cpus_per_task} {input} > {output}
        '''

rule vcfbub:
    input:
        rules.vg_deconstruct.output
    output:
        "{prefix}/Pangenome-out/final/{prefix}.bub.vcf"
    resources:
        cpus_per_task = config["deconstruction_cpu"],
        mem_mb_per_cpu = config["deconstruction_mem"],
        runtime = config["deconstruction_time"]
    shell:
        '''
        vcfbub -l 0 -a 100000 --input {input} > {output}
        '''

# needs vcfwave and bcftools in PATH
# remove INFO fields to reduce file size; allele traversal INFO field can be checked in raw file for variants of subsequent VCFs if necessary
# simplify complex variants as much as possible into simple ones
# takes 1-2 hrs using 12 cores on 4-assembly graph
rule vcfwave:
    input:
        rules.vcfbub.output
    output:
        "{prefix}/Pangenome-out/final/{prefix}.wavey.vcf"
    resources:
        cpus_per_task = config["deconstruction_cpu"],
        mem_mb_per_cpu = config["deconstruction_mem"],
        runtime = config["deconstruction_time"]
    params:
        skip_size = config["skip_size"]
    shell:
        '''
        bcftools annotate -x INFO {input} |\
        vcfwave -t {resources.cpus_per_task} -L {params.skip_size} > {output}
        '''

# needs bcftools in path
# renaming must be done for the reference file to have the same naming as the deconstructed vcf
# rename chromosomes first, then split multi- into biallelic sites, delete duplicate lines if the same type, and finally sort
rule bcftools_norm:
    input:
        rules.vcfwave.output
    output:
        "{prefix}/Pangenome-out/final/{prefix}.norm.vcf"
    resources:
        cpus_per_task = config["deconstruction_cpu"],
        mem_mb_per_cpu = config["deconstruction_mem"],
        runtime = config["deconstruction_time"]
    params:
        ref = config["ref_path"],
        tmp_dir = "{prefix}/Pangenome-out/final/bcf-tmp"
    run:
        import os

        tmp_dir = params["tmp_dir"]
        os.makedirs(tmp_dir, exist_ok=True)

        threads = resources["cpus_per_task"]
        ref = params["ref"]
        infile = input[0]
        outfile = output[0]

        if config["rename_chroms"]:
            shell(f"sed 's/ARS_UCD2#0#//g' {infile} | "
                  f"bcftools norm --threads {threads} -m -any -f {ref} - | "
                  f"bcftools norm --threads {threads} -d none | "
                  f"bcftools sort -T {tmp_dir} -o {outfile}")
        else:
            shell(f"bcftools norm --threads {threads} -m -any -f {ref} {infile} | "
                  f"bcftools norm --threads {threads} -d none | "
                  f"bcftools sort -T {tmp_dir} -o {outfile}")

# needs bcftools in path
# there seeems to be a bug when piping for bcftools norm -a, so that it misses some variants
# splits the VCF in structural (>= 50 bp) and short (< 50 bp) variants; ILEN is calculated on the fly if not present
# for the short variants, it normalizes again, removes duplicates, applies a minimum allele count of 1, joins biallelics, sorts, annotates and finally indexes the VCF
rule bcftools_view:
    input:
        rules.bcftools_norm.output
    output:
        SV = "{prefix}/Pangenome-out/final/{prefix}.SV.vcf",
        small = "{prefix}/Pangenome-out/final/{prefix}.small.vcf"
    resources:
        cpus_per_task = config["default_cpu"],
        mem_mb_per_cpu = config["default_mem"],
        runtime = config["default_time"]
    params:
        tmp_dir = "{prefix}/Pangenome-out/final/bcf-tmp",
        tmp_file = "{prefix}/Pangenome-out/final/{prefix}.small.tmp.vcf"
    shell:
        '''
        bcftools view -i 'abs(ILEN)>=50' {input} |\
        bcftools norm -m +both |\
        bcftools norm --rm-dup exact |\
        bcftools view -c 1  > {output.SV}


        bcftools view -e 'abs(ILEN)>=50' {input} |\
        bcftools norm --threads {resources.cpus_per_task} -a > {params.tmp_file} # there is a bug in bcftools if piping this command, so save it to a file first
        bcftools norm -m +both {params.tmp_file} |\
        bcftools norm --rm-dup exact |\
        bcftools view -c 1 |\
        bcftools sort -T {params.tmp_dir} |\
        bcftools annotate -x INFO -o {output.small}

        rm {params.tmp_file}
        '''
