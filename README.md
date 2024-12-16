

# UMCUGenetics/DxNextflowPRS

[![GitHub Actions CI Status](https://github.com/nf-core/prs/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/prs/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/prs/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/prs/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**UMCUGenetics/DxNextflowPRS** is a bioinformatics pipeline that calculates Polygenic Risk Scores on a panel of samples. PRS models can be either provided by the user, or will be downloaded automatically from PGS Catalog based on a PGSC identifier.

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->


1. Create a regions file for 'targeted' variant calling from either the custom PRS model or a PGSC model
2. Read BAM files
3. Variant Calling (including -ERC BP_RESOLUTION) ([`GATK`](https://gatk.broadinstitute.org/hc/en-us))
4. Combine gVCF files ([`GATK`](https://gatk.broadinstitute.org/hc/en-us))
5. Index gVCF file (([`bcftools`](https://samtools.github.io/bcftools/bcftools.html))
6. Genotype gVCF file (Including non-variant sites [`GATK`](https://gatk.broadinstitute.org/hc/en-us))
7. (Impute missing alt alleles `optional step`)
8. Prepare samplesheet
9. Calculate PRS scores ([`pgsc_calc`](https://github.com/PGScatalog/pgsc_calc))
10. Normalise PRS scores (Custom/[`pgsc_calc`](https://github.com/PGScatalog/pgsc_calc))
12. QC ([`MultiQC`](http://multiqc.info/))

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate): -->

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,bam,bai
Sample1,sample1.bam,sample1.bam.bai
Sample2,sample2.bam,sample2.bam.bai
```


Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run DxNextflowPRS/main.nf \
   --input samplesheet.csv \
   --outdir <OUTDIR> \
   --genome_fasta <genome.fa> \
   --genome_dict <genome.dict> \
   --dbsnp <dbsnp.vcf.gz> \
   --PGS_ID "PGS000004"
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

UMCUGenetics/PRS was originally written by Joris van Steenbrugge.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/prs for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

