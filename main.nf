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



workflow run_tasks{
    tasks = Channel.fromPath(params.input_tasks).splitCsv(header: false, sep: '\t').map(row -> row[0])
    CREATE_PSMS(tasks)
    COLLECT_SUCCESFULL_TASKS(CREATE_PSMS.out[0].collect())
}

workflow get_and_run_tasks{
    tasks_file = GET_TASKS(params.dataset_link)
    tasks = tasks_file.splitCsv(header: false, sep: '\t').map(row -> row[0])
    CREATE_PSMS(tasks)
    COLLECT_SUCCESFULL_TASKS(CREATE_PSMS.out[0].collect())
}