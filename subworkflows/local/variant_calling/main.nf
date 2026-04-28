include { GATK4_HAPLOTYPECALLER } from '../../../modules/nf-core/gatk4/haplotypecaller/main' 

workflow VARIANT_CALLING {
    take:
    ch_samplesheet
    ch_genome_fasta
    ch_genome_index
    ch_genome_dict
    ch_dbsnp
    ch_dbsnp_index
    ch_snp_list
    ch_snp_vcf
    

    main:

    // [model_meta, snplist, vcf, tbi]
    ch_per_model = ch_snp_list.join(ch_snp_vcf)

    ch_hc = ch_samplesheet.combine(ch_per_model)
        .multiMap { sm, bam, bai, mm, snplist, vcf, tbi ->
            def meta = [
                id: "${sm.id}__${mm.id}",
                sample_id: sm.id,
                model_id: mm.id,
                mu: mm.mu,
                sd: mm.sd,
                alpha: mm.alpha,
            ]
            input:   [meta, bam, bai, snplist, []]
            alleles: [[id: meta.id], vcf, tbi]
        }

    GATK4_HAPLOTYPECALLER(
        ch_hc.input,
        ch_genome_fasta,
        ch_genome_index,
        ch_genome_dict,
        ch_dbsnp,
        ch_dbsnp_index,
        ch_hc.alleles
    )

    // Collate software versions
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(GATK4_HAPLOTYPECALLER.out.versions)

    emit:
    vcf         = GATK4_HAPLOTYPECALLER.out.vcf
    tbi         = GATK4_HAPLOTYPECALLER.out.tbi
    ch_versions = ch_versions
}
