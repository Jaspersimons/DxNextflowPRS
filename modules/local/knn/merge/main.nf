process ANCESTRY_KNN_MERGE {
    tag "ANCESTRY_KNN_MERGE"
    label "process_low"
    container "ghcr.io/astral-sh/uv:python3.13-bookworm"

    input:
    path(knn_tsvs)

    output:
    path("ancestry_knn_mqc.tsv"), emit: knn_mqc_tsv

    script:
    """
    echo "Sample ID\tPrediction Group\tConfidence" > ancestry_knn_mqc.tsv
    
    for f in ${knn_tsvs}; do
        tail -n 1 \$f >> ancestry_knn_mqc.tsv
    done
    """
}
