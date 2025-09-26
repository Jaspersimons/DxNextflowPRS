include { BCFTOOLS_SORT } from "../../../modules/nf-core/bcftools/sort/main"
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

    BCFTOOLS_SORT(GET_VCF.out.vcf)

    PGSCATALOG_COMBINE(
        ch_PRS_model,
        params.assembly_version
    )
    ch_versions = ch_versions.mix(PGSCATALOG_COMBINE.out.versions)

    emit:
    list             = GET_PGSC_SNPLIST.out.list
    vcf              = BCFTOOLS_SORT.vcf.collect()
    tbi              = BCFTOOLS_SORT.out.tbi.collect()
    normalised_model = PGSCATALOG_COMBINE.out.normalised_model
    ch_versions      = ch_versions
}
