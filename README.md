

# UMCUGenetics/DxNextflowPRS


-->
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**UMCUGenetics/DxNextflowPRS**

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->


## Usage

First, prepare a samplesheet with your input data that looks as follows:
(note: use absolute filepaths)
`samplesheet.csv`:

```csv
sample,bam,bai
Sample1,sample1.bam,sample1.bam.bai
Sample2,sample2.bam,sample2.bam.bai
```


### HPC

On the HPC you can submit a pipeline run using the `run_dxnextflowprs.sh` script. This submits the pipeline in an sbatch and runs nextflow with a slurm profile.

``` sh
./DxNextflowPRS/run_dxnextflowprs.sh \
    --input <samplesheet.csv> \
    --outdir <path> \
    --email <address> \
    [options]
```

### Alternatively
The pipeline can also be executed using a regular nextflow run command.

``` sh
nextflow run DxNextflowPRS/main.nf \
    --input <samplesheet.csv> \
    --outdir <path> \
    --email <adress> \
    --profile <standard|docker|singularity> \
    [options]
```


# NF-test
Tests are also automatically run on pull requests. A pipeline level test can be executed using:

``` sh
cd DxNextflowPRS
nf-test test ./tests/default.nf.test --profile <docker|singularity>
```

This will test the pipeline execution using the `-stub-run` option; mocking process execution.

Similarly, individual units of the pipeline can be tested using tags.

``` sh
cd DxNextflowPRS
# All local modules/subworkflows
nf-test test . --tag=local
# All local subworkflows
nf-test test . --tag=subworkflows/local
# All local modules
nf-test test . --tag=modules/local

# To see all available tags
nf-test list  --tags
```

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/prs for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->
<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).
