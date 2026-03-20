include { PGSCATALOG_MATCH } from "../../../modules/local/pgscatalog/match/main"
include { PGS_NORM         } from "../../../modules/local/pgs_norm/main"
include { PLINK2_SCORE     } from '../../../modules/nf-core/plink2/score/main'
include { PLINK2_VCF       } from "../../../modules/nf-core/plink2/vcf/main"

workflow CALC_SCORES {
    take:
    ch_vcf
    ch_normalised_model

    main:

    PLINK2_VCF(
        ch_vcf
    )

    PGSCATALOG_MATCH(
        PLINK2_VCF.out.pvar_zst,
        ch_normalised_model.collect()
    )


    PLINK2_SCORE(
        PLINK2_VCF.out.pgen
            .join(PLINK2_VCF.out.psam)
            .join(PLINK2_VCF.out.pvar)
            .join(PLINK2_VCF.out.afreq)
            .join(PGSCATALOG_MATCH.out.scorefile)
    )

    PGS_NORM(
        PLINK2_SCORE.out.score,
        params.model_mu,
        params.model_sd,
    )


    // Collate software versions
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(PLINK2_VCF.out.versions)
    ch_versions = ch_versions.mix(PGSCATALOG_MATCH.out.versions)
    ch_versions = ch_versions.mix(PLINK2_SCORE.out.versions)

    emit:
    ch_versions       = ch_versions
    ch_score_norm     = PGS_NORM.out.tsv
    ch_score_variants = PGSCATALOG_MATCH.out.log
    ch_score          = PGSCATALOG_MATCH.out.scorefile
    ch_score_summary  = PGSCATALOG_MATCH.out.summary
    ch_pgen           = PLINK2_VCF.out.pgen
    ch_psam           = PLINK2_VCF.out.psam
    ch_pvar           = PLINK2_VCF.out.pvar_zst
    ch_vmiss_gz       = PLINK2_VCF.out.vmiss_gz
    ch_afreq_gz       = PLINK2_VCF.out.afreq_gz

}
