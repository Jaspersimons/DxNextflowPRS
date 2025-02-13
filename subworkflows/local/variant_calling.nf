include { BCFTOOLS_INDEX        } from '../../modules/nf-core/bcftools/index/main'
include { GATK4_COMBINEGVCFS    } from '../../modules/nf-core/gatk4/combinegvcfs/main'
include { GATK4_GENOTYPEGVCFS   } from '../../modules/nf-core/gatk4/genotypegvcfs/main'
include { GATK4_HAPLOTYPECALLER } from '../../modules/nf-core/gatk4/haplotypecaller/main'

workflow VARIANT_CALLING {

    take:
    ch_samplesheet
    ch_genome_fasta
    ch_genome_index
    ch_genome_dict
    snp_list


    main:

     ch_dbsnp = Channel.fromPath("${params.dbsnp}")
        .map{ file -> [['id': file.getSimpleName()], file] }.collect()

    ch_dbsnp_index = Channel.fromPath("${params.dbsnp}.tbi")
        .map{ file -> [['id': file.getSimpleName()], file] }.collect()


    GATK4_HAPLOTYPECALLER(
        ch_samplesheet
            .combine(snp_list.map{meta, path -> path})
            .map{meta, bam, bai, tsv -> [meta, bam, bai, tsv, []]},
        ch_genome_fasta,
        ch_genome_index,
        ch_genome_dict,
        ch_dbsnp,
        ch_dbsnp_index
    )

    GATK4_HAPLOTYPECALLER.out.vcf
                   .map{meta, vcf -> vcf}
                   .collect()
    .set{ch_vcf_list}

    GATK4_HAPLOTYPECALLER.out.tbi
                   .map{meta, tbi -> tbi}
                   .collect()
    .set{ch_tbi_list}

    GATK4_COMBINEGVCFS(
        ch_vcf_list
            .concat(ch_tbi_list).collect(flat: false)
            .map{ vcf, tbi -> [['id': 'cohort'], vcf,tbi] },
        snp_list.map{meta, path -> path},
        ch_genome_fasta.map{ meta, fasta -> fasta },
        ch_genome_index.map{ meta, fai -> fai },
        ch_genome_dict.map{ meta, dict -> dict }
    )


    

    BCFTOOLS_INDEX(
        GATK4_COMBINEGVCFS.out.combined_gvcf
    )



    GATK4_GENOTYPEGVCFS(
        GATK4_COMBINEGVCFS.out.combined_gvcf
            .join(BCFTOOLS_INDEX.out.tbi)
            .map{ meta, vcf, tbi -> [meta, vcf, tbi, [], [] ] },
        ch_genome_fasta,
        ch_genome_index,
        ch_genome_dict,
        ch_dbsnp,
        ch_dbsnp_index
    )

    emit:
    vcf = GATK4_GENOTYPEGVCFS.out.vcf
    tbi = GATK4_GENOTYPEGVCFS.out.tbi

}
