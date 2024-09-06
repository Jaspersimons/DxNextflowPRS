process PLINK_QC {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink:1.90b6.21--h779adbc_1' :
        'biocontainers/plink:1.90b6.21--h779adbc_1' }"

    input:
    tuple val(meta), path(target_prefix)

    output:
    tuple val(meta), path("*.QC.*"), emit: QC
    tuple val(meta), path("*.QC.het"), emit: het
    tuple val(meta), path("*.QC.prune.in"), emit: valid_SNPs

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def maf_threshold = task.ext.maf_threshold ?: 0.01
    def hwe_threshold = task.ext.hwe_threshold ?: 1e-6
    def geno_threshold = task.ext.geno_threshold ?: 0.01
    def mind_threshold = task.ext.mind_threshold ?: 0.01
    def window_size = task.ext.window_size ?: 200
    def step_size = task.ext.step_size ?: 50
    def LD_R2_threshold = task.ext.LD_R2_threshold ?: 0.25
    """
    plink \\
        --bfile ${prefix} \\
        --maf ${maf_threshold} \\
        --hwe ${hwe_threshold} \\
        --geno ${geno_threshold} \\
        --mind ${mind_threshold} \\
        --write-snplist \\
        --make-just-fam \\
        --out ${prefix}.QC

    plink \\
        --bfile ${prefix} \\
        --keep ${prefix}.QC.fam \\
        --extract ${prefix}.QC.snplist \\
        --indep-pairwise ${window_size} ${step_size} ${LD_R2_threshold} \\
        --out ${prefix}.QC

    plink \\
        --bfile ${prefix} \\
        --extract ${prefix}.QC.prune.in \\
        --keep ${prefix}.QC.fam \\
        --het \\
        --out ${prefix}.QC
    """
}

process FILTER_HETZYGOSITY {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/mulled-v2-17bee98254312feea8324cad0f703d137d716132:45c657e542c88c3d508d219160e6345ab831d3ad-0' :
        'biocontainers/mulled-v2-17bee98254312feea8324cad0f703d137d716132:45c657e542c88c3d508d219160e6345ab831d3ad-0'}"
    

    input:
    tuple val(meta), path(hetzygosities)

    output:
    tuple val(meta), path("*.valid.sample"), emit: samples_keep

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    Rscript ${moduleDir}/filter_hetzygosity.R ${hetzygosities} ${prefix}.valid.sample
    """

}

process FILTER_RELATEDNESS {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/plink:1.90b6.21--h779adbc_1' :
        'biocontainers/plink:1.90b6.21--h779adbc_1' }"

    input:
    tuple val(meta), path(target_prefix)
    tuple val(meta2), path(valid_samples)
    tuple val(meta3), path(valid_SNPs)

    output:
    tuple val(meta), path("*.QC.rel.id"), emit: rel_id
    
    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def rel_threshold = task.ext.rel_threshold ?: 0.125
    """
    plink \\
        --bfile ${prefix} \\
        --extract ${prefix}.QC.prune.in \\
        --keep ${valid_samples} \\
        --rel-cutoff ${rel_threshold} \\
        --out ${prefix}.QC
    """
}

process FINALIZE_QC {
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/plink:1.90b6.21--h779adbc_1' :
        'biocontainers/plink:1.90b6.21--h779adbc_1' }"

    input:
    tuple val(meta), path(target_prefix), path(rel_id), path(snp_list)

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    plink \\
        --bfile ${prefix} \\
        --make-bed \\
        --keep ${rel_id} \\
        --extract ${snp_list} \\
        --out ${prefix}.QC
    """
} 
