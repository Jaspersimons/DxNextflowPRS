process GET_PGSC_SNPLIST {
    tag "SNP list $prefix"

    container "oras://community.wave.seqera.io/library/pandas_requests:19b30306ab9be7a6"

    input:
    tuple val(meta), path(scoring_file)
    val assembly_version

    output:
    tuple val(meta), path("*_snplist.list"), emit: list
    tuple val(meta), path("*_snplist.tsv"), emit: tsv


    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    get_snp_list.py \\
        --scoring_file ${scoring_file} \\
        --build ${assembly_version} \\
        --prefix ${prefix}

    cat ${prefix}_snplist.list | \\
        tr ":" "\t" | \\
        tr "-" "\t" | \\
        cut -f 1,2 | \\
        sed 's/chr//g' \\
        > ${prefix}_snplist.tsv

    export prefix=${prefix}
    """

    stub:
    def prefix = PGS_ID ?: "${meta.id}"
    """
    touch ${prefix}_snplist.list
    touch ${prefix}_snplist.tsv
    """
}
