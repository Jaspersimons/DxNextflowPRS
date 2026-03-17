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

    ch_alleles = ch_snp_vcf.collect()

    GATK4_HAPLOTYPECALLER(
        ch_samplesheet.combine(
            ch_snp_list.map { _meta, path -> path }
        ).map { meta, bam, bai, tsv -> [meta, bam, bai, tsv, []] },
        ch_genome_fasta,
        ch_genome_index,
        ch_genome_dict,
        ch_dbsnp,
        ch_dbsnp_index,
        ch_alleles
    )

    // Collate software versions
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(GATK4_HAPLOTYPECALLER.out.versions)

    emit:
    vcf         = GATK4_HAPLOTYPECALLER.out.vcf
    tbi         = GATK4_HAPLOTYPECALLER.out.tbi
    ch_versions = ch_versions
}
