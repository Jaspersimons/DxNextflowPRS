include { PGSCATALOG_MATCH } from "../../modules/local/pgscatalog/match/main"
include { PGS_NORM } from "../../modules/local/pgs_norm/main"
include { PLINK2_SCORE } from '../../modules/nf-core/plink2/score/main'
include { PLINK2_VCF } from "../../modules/nf-core/plink2/vcf/main"

workflow CALC_SCORES {
	take:
	ch_vcf
	ch_normalised_model

	main:
	ch_versions = Channel.empty()

	PLINK2_VCF(
		ch_vcf
	)
	ch_versions = ch_versions.mix(PLINK2_VCF.out.versions)

	PGSCATALOG_MATCH(
		ch_normalised_model,
		PLINK2_VCF.out.pvar_zst,
	)
	ch_versions = ch_versions.mix(PGSCATALOG_MATCH.out.versions)

	PLINK2_SCORE(
		PLINK2_VCF.out.pgen
			.join(PLINK2_VCF.out.psam)
			.join(PLINK2_VCF.out.pvar)
			.join(PLINK2_VCF.out.afreq),
		PGSCATALOG_MATCH.out.scorefile.map { _meta, path -> path },
	)
	ch_versions = ch_versions.mix(PLINK2_SCORE.out.versions)

	PGS_NORM(
		PLINK2_SCORE.out.score,
		params.model_mu,
		params.model_sd,
	)

	emit:
	ch_versions = ch_versions
}
