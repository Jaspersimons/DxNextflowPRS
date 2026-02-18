include { PGSCATALOG_ANCESTRY  } from "../../../modules/local/pgscatalog/Ancestry/main"
include { GENERATE_SAMPLESHEET } from "../../../modules/local/samplesheet/main"


workflow ANCESTRY_CHECK {
    take:
    ch_ancestry_db
    ch_plink
    ch_scorefile

    main:

    // make samplesheet
    GENERATE_SAMPLESHEET(
        ch_plink,
        "",
        "pfile"
    )
    PGSCATALOG_ANCESTRY(
        GENERATE_SAMPLESHEET.out.samplesheet,
        ch_scorefile,
        ch_ancestry_db,
        Channel.of([[id: 'slurm_config'], file("${projectDir}/assets/slurm.config")]),
        params.pgsc_version
        
    )
    
    
    
}
