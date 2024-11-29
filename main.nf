#!/usr/bin/env nextflow
log.info """\
    MASSIVEKB - N F   P I P E L I N E
    ===================================
    """
    .stripIndent(true)

include { DOWNLOAD_METADATA     } from './modules.nf'
include { EXTRACT_METADATA     } from './modules.nf'
include { DOWNLOAD_MZTAB    } from './modules.nf'
include { EXTRACT_MZTAB    } from './modules.nf'


/*workflow {
    zip_data = DOWNLOAD_METADATA(params.dataset_link)
    data = EXTRACT_METADATA(zip_data)
    unique_ids = data.splitCsv(header: true, sep: '\t').map(row -> row.proteosafe_task).unique()
    zips_mztab = DOWNLOAD_MZTAB(unique_ids)
    mztab = EXTRACT_MZTAB(zips_mztab)

}*/

workflow {
    unique_ids = Channel.fromPath(tsvfiles).splitCsv(header: true, sep: '\t').map(row -> row.proteosafe_task).unique()
    unique_ids.view()
    //links = unique_ids.map{ id -> "https://proteomics2.ucsd.edu/ProteoSAFe/result.jsp?task=${id}&view=view_result_list"}
    //links.view()
    zips_mztab = DOWNLOAD_MZTAB(unique_ids)
    mztab = EXTRACT_MZTAB(zips_mztab)
    mztab.view()
}