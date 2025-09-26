include { GET_SNPLIST   } from "../../../modules/local/SNPlist/main"
include { GET_VCF       } from "../../../modules/local/gatk_vcf/main"
include { PGSCATALOG_COMBINE } from "../../../modules/local/pgscatalog/combine/main"


workflow PRS_INTERVALS {

    main:
    ch_versions = Channel.empty()

    ch_PRS_model = Channel.fromPath(params.prs_model)
        .map{ path -> [ ['id': path.getSimpleName()], path ] }
        .collect()

    GET_SNPLIST(
        ch_PRS_model,
        params.assembly_version
    )

    GET_VCF(
        ch_PRS_model,
        params.assembly_version
    )

    PGSCATALOG_COMBINE(
        ch_PRS_model,
        params.assembly_version
    )
    ch_versions = ch_versions.mix(PGSCATALOG_COMBINE.out.versions)

    emit:
    list             = GET_PGSC_SNPLIST.out.list
    vcf              = GET_PGSC_VCF.out.vcf.collect()
    tbi              = GET_PGSC_VCF.out.tbi.collect()
    normalised_model = PGSCATALOG_COMBINE.out.normalised_model
    ch_versions      = ch_versions
}
