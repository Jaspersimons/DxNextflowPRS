process PGS_NORM {
    label 'process_single'
    container "oras://community.wave.seqera.io/library/pandas_requests:19b30306ab9be7a6"

    input:
    path(pgsc_calc_outdir)
    val(mu)
    val(sd)

    output:
    path("normalised_counts.tsv"), emit: tsv

    script:
    def prs = "${pgsc_calc_outdir}/Cohort/score/aggregated_scores.txt.gz"
    """


    python ${moduleDir}/normalise_counts.py \\
        --PRS ${prs} \\
        --mu ${mu} \\
        --SD ${sd} \\
        -o normalised_counts.tsv

    """

}
