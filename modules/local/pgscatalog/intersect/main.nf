process PGSCATALOG_INTERSECT {
    tag "${meta.id}"

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/pgscatalog-utils:1.4.4--pyhdfd78af_0'
        : 'biocontainers/pgscatalog-utils:1.4.4--pyhdfd78af_0'}"

    input:
    tuple val(meta), path(geno), path(pheno), path(variants), path(vmiss), path(afreq)
    tuple val(meta2), path(ref_geno), path(ref_pheno), path(ref_variants)

    output:
    tuple val(meta), path("${output}.txt.gz"), emit: intersection
    path "intersect_counts*.txt", emit: intersect_count
    path "versions.yml", emit: versions

    script:
    def mem_mb = task.memory.toMega() // plink is greedy
    output = "${meta.id}_matched"
    """
    
    pgscatalog-intersect \\
        --ref ${ref_variants} \\
        --target ${variants} \\
        -v \\
        --outdir . 
        

    mv matched_variants.txt.gz ${output}.txt.gz


    cat <<-END_VERSIONS > versions.yml
    ${task.process.tokenize(':').last()}:
        pgscatalog.match: \$(echo \$(python -c 'import pgscatalog.match; print(pgscatalog.match.__version__)'))
    END_VERSIONS
    """
}
