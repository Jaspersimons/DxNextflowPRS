process GET_PGSC_SNPLIST {
    tag "SNP list $prefix"

    container "oras://community.wave.seqera.io/library/pandas_requests:19b30306ab9be7a6"

    input:
    val PGS_ID
    val assembly_version
    tuple val(meta), path(scoring_file)

    output:
    tuple env(prefix), path("*_snplist.list"), emit: list
    tuple env(prefix), path("*_snplist.tsv"), emit: tsv


    script:
    def score_file = scoring_file ? "--scoring_file ${scoring_file}" : ""
    def pgsID      = PGS_ID ? "--PGSID ${PGS_ID}" : ""
    def build      = assembly_version ? "--assembly_version ${assembly_version}": ""
    def prefix     = PGS_ID ?: "${meta.id}"
    """
    python ${moduleDir}/get_snp_list.py \\
        ${score_file} \\
        ${pgsID} \\
        ${build} \\
        > ${prefix}_snplist.list

    cat ${prefix}_snplist.list | \\
        tr ":" "\t" | \\
        tr "-" "\t" | \\
        cut -f 1,2 | \\
        sed 's/chr//g' \\
        > ${prefix}_snplist.tsv

    export prefix=${prefix}
    """
}
