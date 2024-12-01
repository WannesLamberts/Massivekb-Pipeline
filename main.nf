#!/usr/bin/env nextflow
log.info """\
    MASSIVEKB - N F   P I P E L I N E
    ===================================
    """
    .stripIndent(true)

include { DOWNLOAD_METADATA } from './modules.nf'
include { EXTRACT_METADATA } from './modules.nf'
include { DOWNLOAD_MZTAB } from './modules.nf'
include { EXTRACT_MZTAB } from './modules.nf'
include { GET_PSM } from './modules.nf'
include { DOWNLOAD_MZML_MZXML } from './modules.nf'
include { COMPLETE_ROW } from './modules.nf'



workflow full{
    zip_data = DOWNLOAD_METADATA(params.dataset_link)
    data = EXTRACT_METADATA(zip_data)
    unique_ids = data.splitCsv(header: true, sep: '\t').map(row -> row.proteosafe_task).unique()
    zips_mztab = DOWNLOAD_MZTAB(unique_ids)
    mztab = EXTRACT_MZTAB(zips_mztab)

}

workflow {
    unique_ids = Channel.fromPath("test_data.tsv").splitCsv(header: true, sep: '\t').map(row -> row.proteosafe_task).unique()
    zips_mztab = DOWNLOAD_MZTAB(unique_ids)
    mztab = EXTRACT_MZTAB(zips_mztab)
    GET_PSM(mztab)
    massive_paths = GET_PSM.out[1].splitText()
    massive_paths = massive_paths.map { path -> path.replace('\n', '') }
    outp = DOWNLOAD_MZML_MZXML(massive_paths)
    psms = GET_PSM.out[0]
    psm_rows = psms.splitCsv(sep: '\t')
    psm_rows_joined = psm_rows.join(outp,failOnMismatch: true)
    //COMPLETE_ROW(psm_rows_joined)

}