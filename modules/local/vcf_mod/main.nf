process REPLACE_INF_VCF {
    tag "$meta.id"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.20--h8b25389_0':
        'biocontainers/bcftools:1.20--h8b25389_0' }"

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*_rep.vcf.gz"), emit: vcf

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    zcat $vcf | sed 's/Infinity/500/g' | sed 's/inf/500/g' | bgzip > ${prefix}_rep.vcf.gz
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | bgzip > ${prefix}_rep.vcf.gz
    """
}
