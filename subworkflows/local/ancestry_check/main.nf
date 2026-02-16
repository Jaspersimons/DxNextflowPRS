include { PGSCATALOG_INTERSECT } from "../../../modules/local/pgscatalog/intersect/main"
include { FILTER_VARIANTS      } from "../../../modules/local/pgscatalog/filter_variants/main"

workflow ANCESTRY_CHECK {
    take:
    ch_geno
    ch_pheno
    ch_variants
    ch_vmiss_gz
    ch_afreq_gz

    main:

    ch_db = Channel.of([
        [id: "ancestry_db"],
        file("${params.ancestry_db_prefix}_ALL.pgen", checkIfExists: true),
        file("${params.ancestry_db_prefix}_ALL.psam", checkIfExists: true),
        file("${params.ancestry_db_prefix}_ALL.pvar.zst", checkIfExists: true),
        file("${params.ld_regions}", checkIfExists: true),
        file("${params.ancestry_db_prefix}.king.cutoff.out.id", checkIfExists: true)
    ])

    PGSCATALOG_INTERSECT(
        ch_geno
            .join(ch_pheno)
            .join(ch_variants)
            .join(ch_vmiss_gz)
            .join(ch_afreq_gz),
        ch_db
            .map{ meta, pgen, psam, pvar_zst, _ld, _king ->
                [meta, pgen, psam, pvar_zst]
            }
    )

    FILTER_VARIANTS(
        PGSCATALOG_INTERSECT.out.intersection,  
        ch_db
    )

    
    
}
