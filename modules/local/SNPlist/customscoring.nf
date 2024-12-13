process GET_CUSTOM_SNPLIST {
    tag "SNP list"
    label 'process_single'
    // container "oras://community.wave.seqera.io/library/pandas_requests:19b30306ab9be7a6"

    input:
    path(scoring_file)

    output:
    tuple val(PGS_ID), path("*_snplist.list"), emit: list
    tuple val(PGS_ID), path("*_snplist.tsv"), emit: tsv


    script:
    """


    cat ${scoring_file} | \\
        grep -v "#" | \\
        tail -n +2 | \\
        awk '{print \$1":"\$2"-"\$2 }' \\
        > \$(basename ${scoring_file} .prs)_snplist.list

    cat \$(basename ${scoring_file} .prs)_snplist.listt | \\
        tr ":" "\t" | \\
        tr "-" "\t" | \\
        cut -f 1,2 | \\
        sed 's/chr//g' \\
        > \$(basename ${scoring_file} .prs)_snplist.tsv
    """


}
