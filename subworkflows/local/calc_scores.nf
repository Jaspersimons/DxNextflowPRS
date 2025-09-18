

include { PGSCATALOG_MATCH } from "../../modules/local/pgscatalog/match/main"

workflow CALC_SCORES {

    take:
    ch_vcf

    main:

    ch_ancestry = Channel.fromPath("${params.pgsc_ancestry_db}")


        
 






}
