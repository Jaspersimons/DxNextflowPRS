/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { NEXTFLOW_RUN           } from '../modules/local/nextflow/run/main'

include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_prs_pipeline'

include { VARIANT_CALLING        } from '../subworkflows/local/variant_calling'
include { IMPUTE_ALLELES         } from '../subworkflows/local/impute_alleles'
include { PREPARE_SAMPLESHEET    } from '../subworkflows/local/prepare_samplesheet'
include { PRS_INTERVALS          } from '../subworkflows/local/PRS_intervals'

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

    ch_ancestry = Channel.fromPath("${params.pgsc_ancestry_db}")

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    PRS_INTERVALS()


    VARIANT_CALLING(
        ch_samplesheet,
        ch_genome_fasta,
        ch_genome_index,
        ch_genome_dict,
        PRS_INTERVALS.out.list
    )

    if (params.impute_alt_alleles) {

        IMPUTE_ALLELES(
            VARIANT_CALLING.out.vcf,
            VARIANT_CALLING.out.tbi,
            ch_genome_fasta,
            ch_genome_index,
            PRS_INTERVALS.out.tsv
        )

        ch_vcf = IMPUTE_ALLELES.out.vcf

    } else {

        ch_vcf = VARIANT_CALLING.out.vcf

    }



    PREPARE_SAMPLESHEET(
        ch_vcf
    )

    if (params.custom_scoring) {
        NEXTFLOW_RUN (
            'pgscatalog/pgsc_calc',
            params.pgsc_calc_opts,
            PREPARE_SAMPLESHEET.out.samplesheet,
            params.pgsc_calc_config,
            [],
            params.assembly_version,
            params.custom_scoring,
            []
            // ch_ancestry
        )
    }

    if (params.PGS_ID) {
        NEXTFLOW_RUN (
            'pgscatalog/pgsc_calc',
            params.pgsc_calc_opts,
            PREPARE_SAMPLESHEET.out.samplesheet,
            params.pgsc_calc_config,
            params.PGS_ID,
            params.assembly_version,
            [],
            ch_ancestry
        )
    }

    //
    // Collate and save software versions
    //
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
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
