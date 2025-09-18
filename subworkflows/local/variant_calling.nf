include { BCFTOOLS_MERGE        } from '../../modules/nf-core/bcftools/merge/main'
include { GATK4_COMBINEGVCFS    } from '../../modules/nf-core/gatk4/combinegvcfs/main'
include { GATK4_GENOTYPEGVCFS   } from '../../modules/nf-core/gatk4/genotypegvcfs/main'
include { GATK4_HAPLOTYPECALLER } from '../../modules/nf-core/gatk4/haplotypecaller/main'
include { REPLACE_INF_VCF       } from "../../modules/local/vcf_mod/main"

workflow VARIANT_CALLING {

    take:
    ch_samplesheet
    ch_genome_fasta
    ch_genome_index
    ch_genome_dict
    ch_snp_list
    ch_snp_vcf


    main:

    ch_alleles = ch_snp_vcf.collect()

    ch_dbsnp = Channel.fromPath("${params.dbsnp}")
        .map{ file -> [['id': file.getSimpleName()], file] }
        .collect()

    ch_dbsnp_index = Channel.fromPath("${params.dbsnp}.tbi")
        .map{ file -> [['id': file.getSimpleName()], file] }
        .collect()


    GATK4_HAPLOTYPECALLER(
        ch_samplesheet
            .combine(ch_snp_list.map{_meta, path -> path})
            .map{meta, bam, bai, tsv -> [meta, bam, bai, tsv, []]},
        ch_genome_fasta,
        ch_genome_index,
        ch_genome_dict,
        ch_dbsnp,
        ch_dbsnp_index,
        ch_alleles
    )


    GATK4_HAPLOTYPECALLER.out.vcf
                   .map{meta, vcf -> vcf}
                   .collect()
    .set{ch_vcf_list}

    GATK4_HAPLOTYPECALLER.out.tbi
                   .map{meta, tbi -> tbi}
                   .collect()
    .set{ch_tbi_list}

    BCFTOOLS_MERGE(
        ch_vcf_list
            .concat(ch_tbi_list).collect(flat: false)
            .map{ vcf, tbi -> [['id': 'cohort'], vcf,tbi] },
            ch_genome_fasta,
            ch_genome_index
    )

    REPLACE_INF_VCF(
        BCFTOOLS_MERGE.out.vcf
    )

    emit:
    vcf = REPLACE_INF_VCF.out.vcf
    tbi = REPLACE_INF_VCF.out.tbi
}
