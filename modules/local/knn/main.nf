process ANCESTRY_KNN {
    tag "${meta.id}"
    tag "process_medium"

    container "ghcr.io/astral-sh/uv:python3.13-bookworm"

    input:
    tuple val(meta), path(eigenvec)
    tuple val(meta2), path(ref_metadata)

    output:
    tuple val(meta), path("*_knn.tsv"), emit: knn_tsv 

    script:
    def prefix = task.ext.prefix ?: meta.id
    def args = task.ext.args ?: ""
    """
    knn.py \
        --eig ${eigenvec} \\
        --labels ${ref_metadata} \\
        ${args} \\
        --output ${prefix}_knn.tsv
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}_knn.tsv
    """
}
