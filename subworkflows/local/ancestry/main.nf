include { ANCESTRY_KNN } from '../../../modules/local/knn/main'
include { BCFTOOLS_MERGE } from '../../../modules/nf-core/bcftools/merge/main'
include { BCFTOOLS_VIEW } from '../../../modules/nf-core/bcftools/view/main'
include { PLINK2_VCF } from '../../../modules/nf-core/plink2/vcf/main'
include { PLINK2_PCA } from '../../../modules/nf-core/plink2/pca/main'
include { PLINK2_EXTRACT } from '../../../modules/nf-core/plink2/extract/main'
include { PLINK2_INDEPPAIRWISE } from '../../../modules/nf-core/plink2/indeppairwise/main'

workflow ANCESTRY {
    take:
    ch_vcf
    ch_ref_vcf
    ch_ref_meta
    ch_genome
    ch_genome_index

    main:

    

    BCFTOOLS_VIEW(
        ch_ref_vcf,
        ch_vcf,
        [],
        []
    )

    ch_merge_input = ch_vcf.combine(BCFTOOLS_VIEW.out.vcf
                                    .join(BCFTOOLS_VIEW.out.tbi))
        .map{ meta_sample, vcf_sample, tbi_sample, _meta_ref, vcf_ref, tbi_ref ->
            tuple(meta_sample, [vcf_sample, vcf_ref], [tbi_sample, tbi_ref])
        }
    
    BCFTOOLS_MERGE(
        ch_merge_input,
        ch_genome,
        ch_genome_index
    )

    PLINK2_VCF(
        BCFTOOLS_MERGE.out.vcf
    )

    
    PLINK2_INDEPPAIRWISE(
        PLINK2_VCF.out.pgen
            .join(PLINK2_VCF.out.pvar)
            .join(PLINK2_VCF.out.psam),
        200,
        50,
        0.2
    )

    PLINK2_EXTRACT(
        PLINK2_VCF.out.pgen
            .join(PLINK2_VCF.out.psam)
            .join(PLINK2_VCF.out.pvar)
            .join(PLINK2_INDEPPAIRWISE.out.prune_in)
    )

    PLINK2_PCA(
        PLINK2_EXTRACT.out.extract_pgen
            .join(PLINK2_EXTRACT.out.extract_psam)
            .join(PLINK2_EXTRACT.out.extract_pvar),
        5,
        false
    )

    ANCESTRY_KNN(
        PLINK2_PCA.out.evecfile,
        ch_ref_meta
    )
}
