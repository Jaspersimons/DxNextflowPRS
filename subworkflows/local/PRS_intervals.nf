include { GET_PGSC_SNPLIST   } from '../../modules/local/SNPlist/pgsc'
include { GET_CUSTOM_SNPLIST } from '../../modules/local/SNPlist/customscoring'
include { GET_SCORING_BUILD  } from '../../modules/local/SNPlist/scoring_build'


workflow PRS_INTERVALS {

    main:

    if (params.custom_scoring && params.PGS_ID){
        throw new RuntimeException(
            "Using both custom_scoring and PGS_ID is currently unsupported"
        )
    }

    if (params.custom_scoring) {

        ch_custom_scoring = Channel.fromPath(params.custom_scoring)
            .map{ path -> [['id': path.getSimpleName()], path] }
            .collect()

        GET_SCORING_BUILD(params.custom_scoring)
        GET_SCORING_BUILD.out.build
            .set{ scoring_build }


        GET_PGSC_SNPLIST(
            [],
            params.assembly_version,
            ch_custom_scoring
        )


    } else {
        GET_PGSC_SNPLIST(
            params.PGS_ID,
            params.assembly_version,
            [[],[]]
        )

    }

    emit:
    list = GET_PGSC_SNPLIST.out.list
    tsv  = GET_PGSC_SNPLIST.out.tsv

}
