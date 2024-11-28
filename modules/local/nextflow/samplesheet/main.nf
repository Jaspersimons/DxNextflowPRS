process GENERATE_SAMPLESHEET {
     // tag "${meta.id}"
    label 'process_single'


    container "oras://community.wave.seqera.io/library/pip_pathlib:2223c5862f409a85"

    input:
    val(path_prefix)
    val(chrom)
    val(format)

    output:
    path 'output_samplesheet.csv', emit: samplesheet

    script:
    def prefix = path_prefix.toString() - ~/\.pgen$/ //getParent()
    def chr = chrom ?: "" 
    def format = format ?: "pfile"
    """
    python ${moduleDir}/create_sample_sheet.py \\
        sampleX \\
        ${prefix} \\
        --format ${format}
    """

}
