
include { BCFTOOLS_ANNOTATE
          as REMOVE_CHR     }        from '../../modules/nf-core/bcftools/annotate/main'
include { BCFTOOLS_ANNOTATE
          as ADD_CHR        }        from '../../modules/nf-core/bcftools/annotate/main'
include { BCFTOOLS_VIEW     }        from '../../modules/nf-core/bcftools/view/main'
include { BCFTOOLS_MERGE    }        from '../../modules/nf-core/bcftools/merge/main'
include { BEAGLE5_BEAGLE    }        from '../../modules/nf-core/beagle5/beagle/main'

workflow IMPUTE_ALLELES {

    take:
    ch_vcf
    ch_tbi
    ch_genome_fasta
    ch_genome_index
    snp_tsv

    main:


    BEAGLE5_BEAGLE(
        ch_vcf,
        params.beagle_refpanel,
        params.genetic_map,
        [:],
        [:]
    )
    // ch_1kgp_vcf = Channel.fromPath("${params.kgp_vcf}")
    //     .map{ file -> [['id': file.getSimpleName()], file] }.collect()

    // ch_1kgp_index =  Channel.fromPath("${params.kgp_vcf}.tbi")
    //     .map{ file -> [['id': file.getSimpleName()], file] }.collect()

    // REMOVE_CHR(
    //     ch_vcf
    //         .join(ch_tbi)
    //         .map {meta, input, index -> [meta, input, index , [], []]},
    //     []
    // )


    // BCFTOOLS_VIEW(
    //     ch_1kgp_vcf.join(ch_1kgp_index),
    //     snp_tsv.map{meta, tsv -> tsv},
    //     [],
    //     []
    // )


    // BCFTOOLS_VIEW.out.vcf
    //     .map{meta, vcf -> vcf}
    //     .concat(
    //         REMOVE_CHR.out.vcf
    //             .map{meta, vcf -> vcf}
    //     ).collect()
    //     .set{merge_vcf_list}

    // BCFTOOLS_VIEW.out.tbi
    //     .map{meta, vcf -> vcf}
    //     .concat(
    //         REMOVE_CHR.out.tbi
    //             .map{meta, vcf -> vcf}
    //     ).collect()
    //     .set{merge_index_list}

    // merge_vcf_list
    //     .concat(merge_index_list)
    //     .collect(flat: false)
    //     .map { vcf, tbi -> [['id': "samples_1kgp"], vcf, tbi] }
    //     .set { merge_list }

    // // ch_vcf_list.concat(ch_tbi_list).collect(flat: false).map{ vcf, tbi -> [['id': 'cohort'], vcf,tbi] }
    // BCFTOOLS_MERGE(
    //     merge_list,
    //     ch_genome_fasta,
    //     ch_genome_index,
    //     [[],[]]
    // )

    emit:
    vcf = BCFTOOLS_MERGE.out.vcf

}
