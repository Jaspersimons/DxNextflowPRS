 process NEXTFLOW_RUN {
    tag "$pipeline_name"

    input:
    val pipeline_name
    val nextflow_opts
    val samplesheet
    val additional_config

    when:
    task.ext.when == null || task.ext.when

    output:
    path("./results/"), emit: result_dir

    shell:
    def conf = additional_config ? "-c $additional_config" : ""
    def samples = "--input $samplesheet"
    """
    nextflow run \\
        ${pipeline_name} \\
        ${nextflow_opts} \\
        ${conf} \\
        ${samples} \\
        "--outdir $task.workDir/results"
    """
}
