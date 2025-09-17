process PRSICE2 {
    tag "$meta.id"

    container "ghcr.io/umcugenetics/prsice2:2.3.5"

    input:
    tuple val(meta), path(base)
    tuple val(meta2), path(target)

    script:
    def args = task.ext.args ?: ''
    """
    Rscript PRSice.R \\
        --dir . \\
        --prsice ./PRSice_linux \\
        --base ${base} \\
        --target ${target} \\
        --thread ${task.cpus}
        ${args}
    """
}
