process GET_SCORING_BUILD {
    tag "scoring_build"
    label 'process_single'

    input:
    path scoring_file

    output:
    env build, emit: build

    script:
    """
    export build=\$(grep "genome_build" "${scoring_file}" | sed 's/#genome_build=//g')
    """
}
