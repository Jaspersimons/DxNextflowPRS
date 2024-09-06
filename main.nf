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
include { FASTQC } from './modules/nf-core/fastqc/main'
include { MULTIQC } from './modules/nf-core/multiqc/main'
include { STANDARD_BASE_QC;
          FILTER_DUPLICATE_BASE;
          FILTER_AMBIGUOUS_BASE } from './modules/local/QC_base/main'
include { PLINK_QC;
          FILTER_HETZYGOSITY;
          FILTER_RELATEDNESS;
          FINALIZE_QC} from './modules/local/QC_target/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Main workflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {


  /*
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      Quality Control
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  */
  Channel.fromPath(params.base_stats)
    .map{file -> [["id": file.getSimpleName()], file]}
    .set{base_input_stats}

  Channel.fromPath("${params.target_prefix}*")
    .map{ file -> [["id": file.getSimpleName()], file] }
    .groupTuple()
    .collect()
    .set{target_data}

  STANDARD_BASE_QC(base_input_stats)
  FILTER_DUPLICATE_BASE(STANDARD_BASE_QC.out.base_sum_statistics)
  FILTER_AMBIGUOUS_BASE(FILTER_DUPLICATE_BASE.out.base_sum_statistics)

  PLINK_QC(target_data)

  FILTER_HETZYGOSITY(PLINK_QC.out.het)

  
  FILTER_RELATEDNESS(target_data, FILTER_HETZYGOSITY.out.samples_keep, PLINK_QC.out.valid_SNPs)

  FINALIZE_QC(target_data
              .join(FILTER_RELATEDNESS.out.rel_id)
              .join(PLINK_QC.out.valid_SNPs)
  )


  /*
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      PRS analysis
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  */
}
