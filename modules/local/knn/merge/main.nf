process ANCESTRY_KNN_MERGE {
    tag "ANCESTRY_KNN_MERGE"
    label "process_low"

    input:
    path(knn_tsvs)

    output:
    path("ancestry_knn_mqc.tsv"), emit: knn_mqc_tsv

    script:
    """
    first=\$(ls -1 ${knn_tsvs} | head -n 1)
    head -n 1 "\$first" | awk 'BEGIN{FS=OFS="\\t"} {print "sample", \$0}' > ancestry_knn_mqc.tsv

  
    for f in ${knn_tsvs}; do
        s=\$(basename "\$f")
        s=\${s%.tsv}
        tail -n +2 "\$f" | awk -v sample="\$s" 'BEGIN{FS=OFS="\\t"} {print sample, \$0}' >> ancestry_knn_mqc.tsv
    done
    """
}
