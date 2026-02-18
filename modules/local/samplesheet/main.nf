process GENERATE_SAMPLESHEET {
    tag "${meta.id}"
    label 'process_single'

    container "ghcr.io/astral-sh/uv:python3.13-bookworm"
    
    input:
    tuple val(meta), val(path_prefix)
    val(chrom)
    val(format)

    output:
    tuple val(meta), path('output_samplesheet.csv'), emit: samplesheet

    script:
    def prefix = path_prefix.toString() - ~/\.pgen$/ //getParent()
    def chr = chrom ?: ""
    def format = format ?: "pfile"
    """
    create_sample_sheet.py \\
        ${meta.id} \\
        ${prefix} \\
        --format ${format}
    """

    stub:
    def prefix = path_prefix.toString() - ~/\.pgen$/
    """
    touch output_samplesheet.csv
    """
}
