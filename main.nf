#!/usr/bin/env nextflow
log.info """\
    MASSIVEKB - N F   P I P E L I N E
    ===================================
    This pipeline is designed for collecting and working with the Human HCD Spectral data on MassiveKB.
    """
    .stripIndent(true)

include { DOWNLOAD_GET_TASKS } from './modules.nf'
include { CREATE_PSMS } from './modules.nf'
include { COLLECT_SUCCESSFUL_TASKS } from './modules.nf'
include { GET_TASKS_FROM_FILE } from './modules.nf'
include { CREATE_PSMS_SIMPLE} from './modules.nf'
include { CALIBRATE} from './modules.nf'
include { TO_PARQUET} from './modules.nf'
include { MERGE } from './modules.nf'
workflow run_tasks{
    /*
        This workflow will generate the completed PSMs for the tasks specified in params.input.
        The resulting PSMs will be saved in the directory out_dir/psms/ with filenames formatted as {task_id}.psms.tsv.
        Additionally, the workflow will create a TSV file containing the IDs of the successfully processed tasks,
        located at out_dir/successful_tasks.tsv.
        The failed tasks can be found in out_dir/Failed_processes.tsv with their exit codes.
    */
    tasks = Channel.fromPath(params.input).splitCsv(header: false, sep: '\t').map(row -> row[0])
    CREATE_PSMS(tasks)
    COLLECT_SUCCESSFUL_TASKS(CREATE_PSMS.out[0].collect())

}

workflow download_and_run_tasks{
    /*
        This workflow will download the metadata file from massiveKB and extract all the uniques tasks from it.
        Then it will generate the completed PSMs for all the tasks.
        The resulting PSMs will be saved in the directory out_dir/psms/ with filenames formatted as {task_id}.psms.tsv.
        Additionally, the workflow will create a TSV file containing the IDs of the successfully processed tasks,
        located at out_dir/successful_tasks.tsv.
        The failed tasks can be found in out_dir/Failed_processes.tsv with their exit codes.
    */
    tasks_file = DOWNLOAD_GET_TASKS(params.dataset_link)
    tasks = tasks_file.splitCsv(header: false, sep: '\t').map(row -> row[0])
    CREATE_PSMS(tasks)
    COLLECT_SUCCESSFUL_TASKS(CREATE_PSMS.out[0].collect())

}

workflow get_tasks_from_file{
    /*
        This workflow will extract all unique tasks from the massiveKB metadata file, with the file location specified in the  parameter.
    */
    input = file(params.input)
    tasks = GET_TASKS_FROM_FILE(input)
}

workflow download_tasks{
    /*
        This workflow will download the massiveKB metadata file and extract the unique tasks,
        which will be saved in a TSV file named tasks.tsv in the specified out_dir.
    */
    params.publish_tasks='True'
    tasks_file = DOWNLOAD_GET_TASKS(params.dataset_link)
}

workflow download_and_run_tasks_simple{
    /*
    This workflow performs the same operations as download_and_run_tasks,
    but it does not extract additional information from mzML/mzXML files.
    */
    tasks_file = DOWNLOAD_GET_TASKS(params.dataset_link)
    tasks = tasks_file.splitCsv(header: false, sep: '\t').map(row -> row[0])
    CREATE_PSMS_SIMPLE(tasks)
    COLLECT_SUCCESSFUL_TASKS(CREATE_PSMS_SIMPLE.out[0].collect())
}
workflow run_tasks_simple{
    /*
    This workflow performs the same operations as run_tasks,
    but it does not extract additional information from mzML/mzXML files.
    */
    tasks = Channel.fromPath(params.input).splitCsv(header: false, sep: '\t').map(row -> row[0])
    CREATE_PSMS_SIMPLE(tasks)
    COLLECT_SUCCESSFUL_TASKS(CREATE_PSMS_SIMPLE.out[0].collect())
}

workflow to_parquet{
    /*
    This workflow combines all TSV files in the specified directory into a single merged.tsv file, adding the provided column names as headers.
    Next, it converts merged.tsv into dataset.parquet.
    Finally, the merged.tsv file is deleted to optimize storage.
    */
    files = file(params.input+'/*.tsv')
    cols  = params.columns.tokenize(',')
    TO_PARQUET(files,cols)

}

workflow calibrate{
    /*
    This process calibrates the retention times for all PSM files in the specified directory.
    It uses the Chronologer dataset as a reference point
    and applies linear regression to predict retention times.
     */
    files = Channel.fromPath(params.input+'/*.tsv')
    chronologer = file(params.chronologer)
    CALIBRATE(files,chronologer)
}