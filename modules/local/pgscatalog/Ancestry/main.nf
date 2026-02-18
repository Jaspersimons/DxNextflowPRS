process PGSCATALOG_ANCESTRY {
    tag "${meta.id}"
    label 'process_low'

    
    input:
    tuple val(meta), path(samplesheet)
    tuple val(meta2), path(scorefile)
    tuple val(meta3), path(ancestry_db)
    tuple val(meta4), path(config)
    val(pgsc_version)

    output:
    tuple val(meta), path("outdir/${meta.id}/score/pop_summary.csv"), emit: popsummary

    script:
    def args = task.ext.args ?: ''
    def build = task.ext.build ? "--target_build ${task.ext.build}" : "--target_build GRCh38"
    """
    nextflow run UMCUGenetics/pgsc_calc -r ${pgsc_version} \\
        ${args} \\
        --input ${samplesheet} \\
        ${build} \\
        --scorefile ${scorefile} \\
        --outdir ./outdir \\
        --run_ancestry ${ancestry_db} \\
        -c ${config} -profile docker
    """
}
