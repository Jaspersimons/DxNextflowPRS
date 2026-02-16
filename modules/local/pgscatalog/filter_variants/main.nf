process FILTER_VARIANTS {
    tag "${meta.id}"
	label 'process_low'

	conda "${moduleDir}/environment.yml"
	container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a2.3--h712d239_1':
        'biocontainers/plink2:2.00a2.3--h712d239_1' }"

    input:
    tuple val(meta), path(shared)
    tuple val(meta2), path(ref_geno), path(ref_pheno), path(ref_var), path(ld), path(king)

    output:
    tuple val(meta2.id), path("*_reference.pgen"), path("*_reference.psam"), path("*_reference.pvar.zst"), emit: ref
    path("*thinned.prune.in.gz"), emit: prune_in
    path("*.afreq.zst"), emit: afreq
    path "versions.yml", emit: versions

    script:
    def mem_mb = task.memory.toMega() // plink is greedy
    // dynamic input option
    def input = (meta.is_pfile) ? '--pfile vzs' : '--bfile vzs'
    """
    # 1. Get QC'd variant set & unrelated samples from REFERENCE data for PCA --

    # PCA_ELIGIBLE == "True"
    awk '(\$13 ~ /^True/) {print \$2}' <(zcat $shared) | gzip -c > shared.txt.gz

    plink2 \\
            --threads $task.cpus \\
            --memory $mem_mb \\
            --pfile ${ref_geno.simpleName} vzs \\
            --remove $king \\
            --extract shared.txt.gz \\
            --max-alleles 2 \\
            --snps-only just-acgt \\
            --rm-dup exclude-all \\
            --geno 0.1 \\
            --mind 0.1 \\
            --maf 0.05 \\
            --hwe 0.0001 \\
            --make-pgen vzs \\
            --allow-extra-chr --autosome \\
            --freq zs \\
            --out ${meta.id}_reference

    # 2. LD-thin variants in REFERENCE (filtered variants & samples) for input
    # into PCA -----------------------------------------------------------------
    plink2 \\
            --threads $task.cpus \\
            --memory $mem_mb \\
            --pfile vzs ${meta.id}_reference \\
            --indep-pairwise 1000 50 0.05 \\
            --exclude range $ld \\
            --out ${ref_geno.simpleName}_thinned

    gzip -f *.prune.in *.prune.out

    cat <<-END_VERSIONS > versions.yml
    ${task.process.tokenize(':').last()}:
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """
}
