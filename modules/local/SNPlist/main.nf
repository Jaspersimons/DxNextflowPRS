process GET_SNPLIST {
    tag "SNP list $PGS_ID"

    container "oras://community.wave.seqera.io/library/pandas_requests:19b30306ab9be7a6"

    input:
    val PGS_ID
    val assembly_version

    output:
    tuple val(PGS_ID), path("*_snplist.list"), emit: list
    tuple val(PGS_ID), path("*_snplist.tsv"), emit: tsv


    script:
    """
    python ${moduleDir}/get_snp_list.py \\
        ${PGS_ID} \\
        ${assembly_version} > ${PGS_ID}_snplist.list

    cat ${PGS_ID}_snplist.list | \\
        tr ":" "\t" | \\
        tr "-" "\t" | \\
        cut -f 1,2 | \\
        sed 's/chr//g' \\
        > ${PGS_ID}_snplist.tsv
    """


}
