#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    UMCUGenetics/DxNextflowPRS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/UMCUGenetics/DxNextflowPRS
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Validate parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { validateParameters; } from 'plugin/nf-schema'
validateParameters()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Import modules/subworkflows
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { BCFTOOLS_ANNOTATE
          as REMOVE_CHR }         from './modules/nf-core/bcftools/annotate/main'
include { BCFTOOLS_ANNOTATE
          as ADD_CHR }            from './modules/nf-core/bcftools/annotate/main'
include { BCFTOOLS_VIEW }         from './modules/nf-core/bcftools/view/main'
include { BCFTOOLS_MERGE }        from './modules/nf-core/bcftools/merge/main'
include { GATK4_COMBINEGVCFS }    from './modules/nf-core/gatk4/combinegvcfs/main'
include { GATK4_GENOTYPEGVCFS }   from './modules/nf-core/gatk4/genotypegvcfs/main'
include { GATK4_HAPLOTYPECALLER } from './modules/nf-core/gatk4/haplotypecaller/main'
include { GENERATE_SAMPLESHEET }  from './modules/local/nextflow/samplesheet/main'
include { GET_SNPLIST }           from './modules/local/SNPlist/main'
include { MULTIQC }               from './modules/nf-core/multiqc/main'
include { NEXTFLOW_RUN }          from './modules/local/nextflow/run/main'
include { PLINK2_VCF }            from './modules/nf-core/plink2/vcf/main'
include { REPLACE_INF_VCF }       from './modules/local/vcf_mod/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Main workflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

  // ch_vcf = Channel.fromPath("${params.vcf_path}/*{.vcf,.vcf.gz}",
  //                           checkIfExists: true)
  //   .map { file -> [['id': file.getSimpleName()], file] }


  ch_genome_fasta = Channel.fromPath("${params.genome_fasta}")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

  ch_genome_fasta_index = Channel.fromPath("${params.genome_fasta}.fai")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

  ch_genome_dict = Channel.fromPath("${params.genome_dict}")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

  ch_dbsnp = Channel.fromPath("${params.dbsnp}")
    .map{ file -> [['id': file.getSimpleName()], file] }.collect()

  ch_dbsnp_index = Channel.fromPath("${params.dbsnp}.tbi")
    .map{ file -> [['id': file.getSimpleName()], file] }.collect()

  ch_1kgp_vcf = Channel.fromPath("${params.kgp_vcf}")
    .map{ file -> [['id': file.getSimpleName()], file] }.collect()

  ch_1kgp_index =  Channel.fromPath("${params.kgp_vcf}.tbi")
    .map{ file -> [['id': file.getSimpleName()], file] }.collect()


  ch_bam = Channel.fromFilePairs(
        "${params.bam_path}/*.{bam,bai}",
        checkIfExists: true) {
            file -> file.name.replaceAll(/.bam|.bai$/,'') }
        .map{ meta, bam_index -> [['id': meta], bam_index[0], bam_index[1]] }

  //
  // When starting with BAM files, get SNP positions for targeted GATK variant
  // calling
  //
  GET_SNPLIST("PGS000004", "GRCh38")



 //
 // Sample Variant calling and Genotyping
 //
 GATK4_HAPLOTYPECALLER(
    ch_bam
      .combine(
        GET_SNPLIST.out.list
          .map{meta, path -> path})
      .map{meta, bam, bai, tsv -> [meta, bam, bai, tsv, []]},
    ch_genome_fasta,
    ch_genome_fasta_index,
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
    ch_vcf_list.concat(ch_tbi_list).collect(flat: false).map{ vcf, tbi -> [['id': 'cohort'], vcf,tbi] },
    ch_genome_fasta.map{ meta, fasta -> fasta },
    ch_genome_fasta_index.map{ meta, fai -> fai },
    ch_genome_dict.map{ meta, dict -> dict }
  )

//meta input inde intervals intervals_idx
  GATK4_GENOTYPEGVCFS(
    GATK4_COMBINEGVCFS.out.vcf
      .join(GATK4_COMBINEGVCFS.out.tbi)
      .map{ meta, vcf, tbi -> [meta, vcf,tbi, [],[]] },
    ch_genome_fasta,
    ch_genome_fasta_index,
    ch_genome_dict,
    ch_dbsnp,
    ch_dbsnp_index
  )

//
// Impute missing Alt alleles
//
  REMOVE_CHR(
    GATK4_GENOTYPEGVCFS.out.vcf
      .join(GATK4_GENOTYPEGVCFS.out.tbi)
      .map {meta, input, index -> [meta, input, index , [], []]},
    []
  )


  BCFTOOLS_VIEW(
    ch_1kgp_vcf.join(ch_1kgp_index),
    GET_SNPLIST.out.tsv.map{meta, tsv -> tsv},
    [],
    []
  )


  BCFTOOLS_VIEW.out.vcf
    .map{meta, vcf -> vcf}
    .concat(
      REMOVE_CHR.out.vcf
      .map{meta, vcf -> vcf}
    ).collect()
    .set{merge_vcf_list}

  BCFTOOLS_VIEW.out.tbi
    .map{meta, vcf -> vcf}
    .concat(
      REMOVE_CHR.out.tbi
      .map{meta, vcf -> vcf}
    ).collect()
    .set{merge_index_list}

  merge_vcf_list
    .concat(merge_index_list)
    .collect(flat: false)
    .map { vcf, tbi -> [['id': "samples_1kgp"], vcf, tbi] }
    .set { merge_list }

  // ch_vcf_list.concat(ch_tbi_list).collect(flat: false).map{ vcf, tbi -> [['id': 'cohort'], vcf,tbi] }
  BCFTOOLS_MERGE(
    merge_list,
    ch_genome_fasta,
    ch_genome_fasta_index
  )




  // Convert VCF to PLINK format
  REPLACE_INF_VCF(BCFTOOLS_MERGE.out.vcf)
  PLINK2_VCF(REPLACE_INF_VCF.out.vcf)

  GENERATE_SAMPLESHEET(
    PLINK2_VCF.out.pgen
      .map { meta, pgen -> [pgen.toString()] },
    "",
    "pfile"
  )

  GENERATE_SAMPLESHEET.out.samplesheet.view()

  // NEXTFLOW_RUN (
  //       'pgscatalog/pgsc_calc',    // Select nf-core pipeline
  //       params.nfcore_demo_opts,   // workflow opts supplied as params for flexibility
  //       params.nfcore_demo_params_file ? Channel.fromPath(params.nfcore_demo_params_file, checkIfExists: true) : Channel.value([]),
  //       params.nfcore_demo_samplesheet ? Channel.fromPath(params.nfcore_demo_samplesheet, checkIfExists: true) : Channel.value([]),
  //       params.nfcore_demo_add_config ? Channel.fromPath(params.nfcore_demo_add_config, checkIfExists: true) : Channel.value([]),
  //   )

}
