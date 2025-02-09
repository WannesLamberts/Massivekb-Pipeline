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

include { DOWNLOAD_GET_TASKS } from './modules_v2.nf'
include { CREATE_PSMS } from './modules_v2.nf'
include { COLLECT_SUCCESSFUL_TASKS } from './modules_v2.nf'
include { GET_TASKS_FROM_FILE } from './modules_v2.nf'
include { CHECK_MZTAB } from './modules_v2.nf'

workflow check_valid_mztabs{
    tasks = Channel.fromPath(params.input_tasks).splitCsv(header: false, sep: '\t').map(row -> row[0])
    all_tasks = Channel.fromPath(params.input_tasks).splitCsv(header: false, sep: '\t').map(row -> row[0])
    CHECK_MZTAB(tasks)
    valid = CHECK_MZTAB.out[0].collect()
    valid.view()
    //COLLECT_SUCCESSFUL_FAILED_TASKS(all_tasks.collect(),CREATE_PSMS.out[0].collect())

}

workflow run_tasks{
    tasks = Channel.fromPath(params.input_tasks).splitCsv(header: false, sep: '\t').map(row -> row[0])
    CREATE_PSMS(tasks)
    COLLECT_SUCCESSFUL_TASKS(CREATE_PSMS.out[0].collect())

}
workflow get_tasks_from_file{
    input_file = file(params.input_file)
    tasks = GET_TASKS_FROM_FILE(input_file)

}
workflow download_and_run_tasks{
    tasks_file = DOWNLOAD_GET_TASKS(params.dataset_link)
    tasks = tasks_file.splitCsv(header: false, sep: '\t').map(row -> row[0])
    CREATE_PSMS(tasks)
    COLLECT_SUCCESSFUL_TASKS(CREATE_PSMS.out[0].collect())
}