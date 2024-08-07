process PLINK_STANDARDQC {
    tag "meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink:1.90b6.21--h031d066_5':
        'biocontainers/plink:1.90b6.21--h031d066_5' }"

    input:
    tuple val(meta), path(base_sum_statistics)


    output:
    tuple val(meta), path("*baseQC.csv.gz"), emit: baseQC
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def MAF_threshold = task.ext.MAF_threshold ?: 0.01
    def INFO_threshold = task.ext.INFO_threshold ?: 0.8

    """
    #/usr/bin/env python
    import pandas as pd

    data = pd.read_csv("${base_sum_statistics}")
    data = data[
        (data["MAF] > ${MAFf_threshold}) &
        (data["INFO"] > ${INFO_threshold})
    ]

    data.to_csv('${prefix}_baseQC.csv.gz', compression='gzip')
    """

    """
    #!/bin/bash
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink: \$(echo \$(plink --version) | sed 's/^PLINK v//;s/64.*//')
    END_VERSIONS
    """
}
