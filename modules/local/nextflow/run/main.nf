 process NEXTFLOW_RUN {
    tag "$pipeline_name"

    input:
    val pipeline_name
    val nextflow_opts
    val samplesheet
    val additional_config
    val PGS_ID
    val assembly_version
    path(custom_scoring)
    path(ancestry)

    when:
    task.ext.when == null || task.ext.when

    output:
    path("./results/"), emit: result_dir

    shell:
    def conf         = additional_config ? "-c $additional_config" : ""
    def samples      = "--input $samplesheet"
    def ancestrydb   = ancestry ? "--run_ancestry $ancestry" : ""
    def model        = PGS_ID ? "--pgs_id $params.PGS_ID" : ""
    def custom_model = custom_scoring ? "--scorefile $custom_scoring": ""
    def build        = "--target_build $assembly_version"
    """
    nextflow run \\
        ${pipeline_name} \\
        ${model} \\
        ${build} \\
        ${custom_model} \\
        ${nextflow_opts} \\
        ${ancestrydb} \\
        ${conf} \\
        ${samples} \\
        "--outdir $task.workDir/results"
    """

    stub:
    """
    mkdir ./results
    """
}
