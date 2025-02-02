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
include { DOWNLOAD_MZML_MZXML } from './modules.nf'
include { CONCATENATE } from './modules.nf'
include { TO_FILE } from './modules.nf'

include { GET_TASKS } from './modules_v2.nf'
include { CREATE_PSMS } from './modules_v2.nf'
include { COLLECT_SUCCESFULL_TASKS } from './modules_v2.nf'



workflow base{
    unique_ids = Channel.fromPath("test_files/one_dataset.tsv").splitCsv(header: true, sep: '\t').map(row -> row.proteosafe_task).unique()
    //unique_ids = Channel.fromPath("../massivekb_dataset/LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv").splitCsv(header: true, sep: '\t').map(row -> row.proteosafe_task).unique()
    zips_mztab = DOWNLOAD_MZTAB(unique_ids)
    mztab = EXTRACT_MZTAB(zips_mztab)
    outp = DOWNLOAD_MZML_MZXML(mztab)
    completed_task_ids = DOWNLOAD_MZML_MZXML.out[0]
    completed_tasks = completed_task_ids.collect()
    TO_FILE(completed_tasks)
}

workflow alternative{
    //GET_TASKS(params.dataset_link)
    tasks = Channel.fromPath("test_files/small_tasks.tsv").splitCsv(header: false, sep: '\t').map(row -> row[0])
    CREATE_PSMS(tasks)
    COLLECT_SUCCESFULL_TASKS(CREATE_PSMS.out[0].collect())
}
workflow {
    tasks = Channel.fromPath("test_files/small_tasks.tsv").splitCsv(header: false, sep: '\t').map(row -> row[0])
    CREATE_PSMS(tasks)
    COLLECT_SUCCESFULL_TASKS(CREATE_PSMS.out[0].collect())
}