include { PGSCATALOG_MATCH } from "../../modules/local/pgscatalog/match/main"
include { PGS_NORM         } from "../../modules/local/pgs_norm/main"
include { PLINK2_SCORE     } from '../../modules/local/plink2/score/main'
include { PLINK2_VCF       } from "../../modules/local/plink2/vcf/main"

workflow CALC_SCORES {
    take:
    ch_vcf
    ch_normalised_model

    main:

    PLINK2_VCF(
        ch_vcf
    )

    PGSCATALOG_MATCH(
        ch_normalised_model,
        PLINK2_VCF.out.pvar_zst
    )

    PLINK2_SCORE(
        PLINK2_VCF.out.pgen
            .join(PLINK2_VCF.out.psam)
            .join(PLINK2_VCF.out.pvar)
            .join(PLINK2_VCF.out.afreq),
        PGSCATALOG_MATCH.out.scorefile
            .map{_meta, path -> path}
    )

    PGS_NORM(
        PLINK2_SCORE.out.score,
        params.model_mu,
        params.model_sd
    )

}
