process STANDARD_BASE_QC {
    tag "meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-1cd0b686a176341c99080e12c8421b9d154ca6ff:907e9d0e7c2849fd1de4404479de65cbdfcc36f9-0':
        'biocontainers/mulled-v2-1cd0b686a176341c99080e12c8421b9d154ca6ff:907e9d0e7c2849fd1de4404479de65cbdfcc36f9-0' }"

    input:
    tuple val(meta), path(base_sum_statistics)


    output:
    tuple val(meta), path("*_MAF_INFO_QC.csv.gz"), emit: base_sum_statistics
    

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def MAF_threshold = task.ext.MAF_threshold ?: 0.01
    def INFO_threshold = task.ext.INFO_threshold ?: 0.8

    """
    #!/usr/bin/env python
    import pandas as pd

    data = pd.read_csv("${base_sum_statistics}", sep=None, engine="python")
    data = data[
        (data["MAF"] > ${MAF_threshold}) &  (data["INFO"] > ${INFO_threshold})
    ]

    data.to_csv('${prefix}_MAF_INFO_QC.csv.gz', compression='gzip')
    """
   
}


process FILTER_DUPLICATE_BASE {
    tag "meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioawk:1.0--he4a0461_12':
        'biocontainers/bioawk:1.0--he4a0461_12' }"


    input:
    tuple val(meta), path(base_sum_statistics)

    output:
    tuple val(meta), path("*nodup.csv.gz"), emit: base_sum_statistics

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    #!/bin/bash

    gunzip -c ${base_sum_statistics} |\
        awk '{seen[\$3]++; if(seen[\$3]==1){ print}}' |\
        gzip - > ${prefix}_nodup.csv.gz
    """
}

process FILTER_AMBIGUOUS_BASE {
    tag "meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioawk:1.0--he4a0461_12':
        'biocontainers/bioawk:1.0--he4a0461_12' }"


    input:
    tuple val(meta), path(base_sum_statistics)

    output:
    tuple val(meta), path("*noambiguous.csv.gz"), emit: base_sum_statistics

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    #!/bin/bash

    gunzip -c ${base_sum_statistics} |\
        awk '!( (\$4=="A" && \$5=="T") || \
            (\$4=="T" && \$5=="A") || \
            (\$4=="G" && \$5=="C") || \
            (\$4=="C" && \$5=="G")) {print}' |\
        gzip - > ${prefix}_noambiguous.csv.gz
    """
}
