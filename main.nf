#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PRS } from './workflows/prs'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_prs_pipeline'
include { PIPELINE_COMPLETION } from './subworkflows/local/utils_nfcore_prs_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
	//
	// SUBWORKFLOW: Run initialisation tasks
	//
	PIPELINE_INITIALISATION(
		params.version,
		params.validate_params,
		params.monochrome_logs,
		args,
		params.outdir,
		params.input,
	)

	//
	//
	// WORKFLOW: Run main workflow
	//
	PRS(PIPELINE_INITIALISATION.out.samplesheet)

	//
	// SUBWORKFLOW: Run completion tasks
	//
	PIPELINE_COMPLETION(
		params.email,
		params.email_on_fail,
		params.plaintext_email,
		params.outdir,
		params.monochrome_logs,
		PRS.out.multiqc_report,
	)
}
