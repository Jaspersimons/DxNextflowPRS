process GET_SNPLIST {
    tag "SNP list $PGS_ID"

    container "oras://community.wave.seqera.io/library/pandas_requests:19b30306ab9be7a6"

    input:
    val PGS_ID
    val assembly_version

    output:
    tuple val(PGS_ID), path("*_snplist.list"), emit: tsv


    script:
    """
    python ${moduleDir}/get_snp_list.py \\
    ${PGS_ID} \\
    ${assembly_version} > ${PGS_ID}_snplist.list
    """


}
