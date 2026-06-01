#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PRS } from './workflows/prs'

include { CALC_SCORES             } from './subworkflows/local/calc_scores/main'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_prs_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_prs_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CALC_SCORES_ONLY {
    //
    // Entry Point: calculate only PRS scores for the given vcf files and model
    //
    def model_id = file(params.normalised_model).getSimpleName()

    ch_normalised_model = channel.fromPath("${params.normalised_model}")
        .map { path -> [ [id: model_id], path ] }

    ch_vcf = channel.fromPath("${params.input}/*.vcf.gz")
        .map { vcf ->
            [ [id: vcf.getSimpleName(), model_id: model_id, mu: params.model_mu, sd: params.model_sd ], vcf ] }



    CALC_SCORES(ch_vcf, ch_normalised_model)
}

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
