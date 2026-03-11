process PGSCATALOG_MATCH {
    tag "${meta.id}"

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/pgscatalog-utils:1.4.4--pyhdfd78af_0'
        : 'biocontainers/pgscatalog-utils:1.4.4--pyhdfd78af_0'}"

    input:
    tuple val(meta), path(scoring_file)
    tuple val(meta2), path(pvar)

    output:
    tuple val(meta2), path("*_summary.csv"), emit: summary
    tuple val(meta2), path("*.scorefile.gz"), emit: scorefile
    tuple val(meta2), path("*_log.csv.gz"), emit: log
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: meta2.id
    def args = task.ext.args ?: ""
    """
    pgscatalog-match \\
        ${args} \\
        --dataset ${prefix} \\
        --scorefiles ${scoring_file} \\
        --target ${pvar} \\
        --outdir ./

    echo "pgscatalog-match: 1.4.4" > versions.yml
    """

    stub:
    def prefix = task.ext.prefix ?: "Cohort"
    """
	touch ${prefix}_summary.csv
	touch ${prefix}.scorefile.gz
    touch ${prefix}_log.csv.gz

	echo "pgscatalog-match: 1.4.4" > versions.yml
	"""
}
