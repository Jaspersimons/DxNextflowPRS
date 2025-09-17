
include { PRSICE2   } from "../../modules/local/PRSice2/main"
include { PLINK_VCF } from '../../modules/nf-core/plink/vcf/main'

include { NEXTFLOW_RUN           } from '../../modules/local/nextflow/run/main'
include { PREPARE_SAMPLESHEET    } from './prepare_samplesheet'

workflow CALC_SCORES {

    take:
    ch_vcf

    main:

    ch_ancestry = Channel.fromPath("${params.pgsc_ancestry_db}")

    if (params.prs_tool == "pgsc_calc"){

        PREPARE_SAMPLESHEET(
            ch_vcf
        )

        NEXTFLOW_RUN (
                'pgscatalog/pgsc_calc',
                params.pgsc_calc_opts,
                PREPARE_SAMPLESHEET.out.samplesheet,
                params.pgsc_calc_config,
                params.PGS_ID,
                params.assembly_version,
                [], //no custom scoring model
                ch_ancestry
        )

        // if (params.custom_scoring) {

        // // Run pgsc_calc without ancestry database
        // if (params.custom_mu && params.custom_sd) {
        //     println("YESYES")
        //     NEXTFLOW_RUN (
        //         'pgscatalog/pgsc_calc',
        //         params.pgsc_calc_opts,
        //         PREPARE_SAMPLESHEET.out.samplesheet,
        //         params.pgsc_calc_config,
        //         [], // no PGS_ID
        //         params.assembly_version,
        //         params.custom_scoring,
        //         [] // no ancestry database

        //     )

        //     PGS_NORM(
        //         NEXTFLOW_RUN.out.result_dir,
        //         params.custom_mu,
        //         params.custom_sd
        //     )

        // // Run pgsc_calc with ancestry database
        // } else {
        //     NEXTFLOW_RUN (
        //         'pgscatalog/pgsc_calc',
        //         params.pgsc_calc_opts,
        //         PREPARE_SAMPLESHEET.out.samplesheet,
        //         params.pgsc_calc_config,
        //         [], // no PGS_ID
        //         params.assembly_version,
        //         params.custom_scoring,
        //         ch_ancestry
        //     )
        // }

        // } else if (params.PGS_ID) {

        // }
    } else if (params.prs_tool == "prsice2") {
        PLINK_VCF(ch_vcf)
        PRSICE2()

    }






}
