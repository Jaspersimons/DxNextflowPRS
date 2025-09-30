
process PGSCATALOG_MATCH {
	tag "${meta.id}"

	container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
		? 'https://depot.galaxyproject.org/singularity/pgscatalog-utils:1.4.4--pyhdfd78af_0'
		: 'biocontainers/pgscatalog-utils:1.4.4--pyhdfd78af_0'}"

	input:
	tuple val(meta), path(scoring_file)
	tuple val(meta2), path(pvar)

	output:
	tuple val(meta), path("*_summary.csv"), emit: summary
	tuple val(meta), path("*.scorefile.gz"), emit: scorefile
	path "versions.yml", emit: versions

	script:
	def prefix = task.ext.prefix ?: "Cohort"
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

	echo "pgscatalog-match: 1.4.4" > versions.yml
	"""
}
