process GET_PGSC_VCF {
    tag "GATK VCF $meta.id"

    container "oras://community.wave.seqera.io/library/bcftools_pandas:6f189f4795a546ee" 

    input:
    tuple val(meta), path(scoring_file)
    val(genome_build)

    output:
    tuple val(meta), path("*_genotypes.vcf.gz"), emit: vcf
    tuple val(meta), path("*_genotypes.vcf.gz.tbi"), emit: tbi


    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    pgs_to_vcf.py \\
        ${scoring_file} \\
        ${prefix}_genotypes.vcf \\
        --genome-build ${genome_build}

    bcftools sort --write-index=tbi -Oz -o ${prefix}_genotypes.vcf.gz ${prefix}_genotypes.vcf
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}_genotypes.vcf.gz
    touch ${prefix}_genotypes.vcf.gz.tbi
    """
}