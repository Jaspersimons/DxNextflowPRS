/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_prs_pipeline'

include { ANCESTRY               } from '../subworkflows/local/ancestry/main'
include { CALC_SCORES            } from '../subworkflows/local/calc_scores/main'
include { PRS_INTERVALS          } from '../subworkflows/local/prs_intervals/main'
include { VARIANT_CALLING        } from '../subworkflows/local/variant_calling/main'

include { SAMPLE_QC              } from '../modules/local/sample_qc/main'
include { MERGE_PRS_MQC          } from '../modules/local/merge_prs_mqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PRS {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    ch_genome_fasta = Channel.fromPath("${params.genome_fasta}")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

    ch_genome_index = Channel.fromPath("${params.genome_fasta}.fai")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

    ch_genome_dict = Channel.fromPath("${params.genome_dict}")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

    ch_dbsnp = Channel.fromPath("${params.dbsnp}")
		.map { file -> [['id': file.getSimpleName()], file] }
		.collect()

    ch_dbsnp_index = Channel.fromPath("${params.dbsnp}.tbi")
		.map { file -> [['id': file.getSimpleName()], file] }
		.collect()


    ch_PRS_model = Channel.fromPath(params.prs_models)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.modelID, mu: row.mu, sd: row.sd, alpha: row.alpha]
            [meta, file("${projectDir}/assets/models/${row.path}")]
        }



    PRS_INTERVALS(ch_PRS_model)

    VARIANT_CALLING(
        ch_samplesheet,
        ch_genome_fasta,
        ch_genome_index,
        ch_genome_dict,
        ch_dbsnp,
        ch_dbsnp_index,
        PRS_INTERVALS.out.list,
        PRS_INTERVALS.out.vcf.join(PRS_INTERVALS.out.tbi)
    )

    CALC_SCORES(
        VARIANT_CALLING.out.vcf,
        PRS_INTERVALS.out.normalised_model
    )



    ch_ref_vcf = Channel.of([
        file("${params.ancestry_db}", checkIfExists: true),
        file("${params.ancestry_db}.tbi", checkIfExists: true)
    ])
        .map { vcf, tbi -> [ [id: vcf.getSimpleName()], vcf, tbi ] }
        .first()
    ch_ref_meta = Channel.fromPath("${params.ancestry_db_meta}")
        .map {meta -> [[id: meta.getSimpleName()], meta]}
        .first()

    ch_ancestry_vcf = VARIANT_CALLING.out.vcf
        .map { meta, vcf -> [meta.sample_id, vcf] }
        .groupTuple()
        .map { sid, vcfs -> [[id: sid], vcfs[0]] }

    ch_ancestry_tbi = VARIANT_CALLING.out.tbi
        .map { meta, tbi -> [meta.sample_id, tbi] }
        .groupTuple()
        .map { sid, tbis -> [[id: sid], tbis[0]] }

    ANCESTRY(
        ch_ancestry_vcf.join(ch_ancestry_tbi),
        ch_ref_vcf,
        ch_ref_meta,
        ch_genome_fasta,
        ch_genome_index
    )


    // QC step — combined meta carries (sample_id, model_id); ancestry is per-sample only.
    SAMPLE_QC(
        CALC_SCORES.out.ch_score_norm
            .join(CALC_SCORES.out.ch_score_summary)
            .map { meta, scores, summary -> [meta.sample_id, meta, scores, summary] }
            .combine(
                ANCESTRY.out.knn_tsv.map { ancestry_meta, knn -> [ancestry_meta.id, knn] },
                by: 0
            )
            .map { _sid, meta, scores, summary, knn -> [meta, scores, knn, summary] }
    )


    MERGE_PRS_MQC(
        SAMPLE_QC.out.score_qc.map{ _meta, tsv -> tsv }.collect()
    )


    //
    // Collate and save software versions
    //
    //
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_versions = ch_versions.mix(PRS_INTERVALS.out.ch_versions)
    ch_versions = ch_versions.mix(VARIANT_CALLING.out.ch_versions)
    ch_versions = ch_versions.mix(CALC_SCORES.out.ch_versions)


    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'prs_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(MERGE_PRS_MQC.out.mqc_tsv)


    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
