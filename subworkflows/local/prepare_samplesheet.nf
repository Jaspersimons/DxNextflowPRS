
include { GENERATE_SAMPLESHEET }  from '../../modules/local/nextflow/samplesheet/main'
include { PLINK2_VCF }            from '../../modules/nf-core/plink2/vcf/main'
include { REPLACE_INF_VCF }       from '../../modules/local/vcf_mod/main'

workflow PREPARE_SAMPLESHEET {

    take:
    vcf

    main:
    //
    // Convert VCF to PLINK format
    //

    REPLACE_INF_VCF(vcf)
    PLINK2_VCF(REPLACE_INF_VCF.out.vcf)

    GENERATE_SAMPLESHEET(
        PLINK2_VCF.out.pgen
            .map { meta, pgen -> [pgen.toString()] },
        "",
        "pfile"
    )


    emit:
    samplesheet = GENERATE_SAMPLESHEET.out.samplesheet

}
