process PGS_NORM {
    tag "${meta.id}"
    label 'process_single'

    container "ghcr.io/astral-sh/uv:python3.13-bookworm"

    input:
    tuple val(meta), path(prs_scores)
    val mu
    val sd

    output:
    path ("*_normalised_counts.tsv"), emit: tsv

    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    normalise_counts.py \\
        --PRS ${prs_scores} \\
        --mu ${mu} \\
        --SD ${sd} \\
        -o ${prefix}_normalised_counts.tsv
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
	touch ${prefix}_normalised_counts.tsv
	"""
}
