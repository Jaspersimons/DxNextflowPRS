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



include { GET_SNPLIST }           from './modules/local/SNPlist/main'
include { MULTIQC }               from './modules/nf-core/multiqc/main'
include { NEXTFLOW_RUN }          from './modules/local/nextflow/run/main'


include { VARIANT_CALLING }       from './subworkflows/local/variant_calling'
include { IMPUTE_ALLELES }        from './subworkflows/local/impute_alleles'
include { PREPARE_SAMPLESHEET }   from './subworkflows/local/prepare_samplesheet'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Main workflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

  ch_genome_fasta = Channel.fromPath("${params.genome_fasta}")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

  ch_genome_index = Channel.fromPath("${params.genome_fasta}.fai")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

  ch_genome_dict = Channel.fromPath("${params.genome_dict}")
        .map{ file -> [file.getSimpleName(), file] }
        .collect()

  ch_bam = Channel.fromFilePairs(
        "${params.bam_path}/*.{bam,bai}",
        checkIfExists: true) {
            file -> file.name.replaceAll(/.bam|.bai$/,'') }
        .map{ meta, bam_index -> [['id': meta], bam_index[0], bam_index[1]] }

  //
  // When starting with BAM files, get SNP positions for targeted GATK variant
  // calling
  //
  GET_SNPLIST(params.PGS_ID, params.assembly_version)

  VARIANT_CALLING(
    ch_bam,
    ch_genome_fasta,
    ch_genome_dict,
    ch_genome_index,
    GET_SNPLIST.out.list
  )

  IMPUTE_ALLELES(
    VARIANT_CALLING.out.vcf,
    VARIANT_CALLING.out.tbi,
    ch_genome_fasta,
    ch_genome_index,
    GET_SNPLIST.out.tsv
  )

  PREPARE_SAMPLESHEET(
    IMPUTE_ALLELES.out.vcf
  )

  NEXTFLOW_RUN (
    'pgscatalog/pgsc_calc',    // Select nf-core pipeline
    params.pgsc_calc_opts,
    PREPARE_SAMPLESHEET.out.samplesheet,
    params.pgsc_calc_config
  )

}
