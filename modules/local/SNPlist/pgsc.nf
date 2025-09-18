process GET_PGSC_SNPLIST {
    tag "SNP list $prefix"

    container "oras://community.wave.seqera.io/library/pandas_requests:19b30306ab9be7a6"

    input:
    tuple val(meta), path(scoring_file)
    val assembly_version

    output:
    tuple val(meta), path("*_snplist.list"), emit: list


    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    get_snp_list.py \\
        --scoring_file ${scoring_file} \\
        --assembly_version ${assembly_version} \\
        --prefix ${prefix}


    export prefix=${prefix}
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}_snplist.list
    touch ${prefix}_snplist.tsv
    """
}
