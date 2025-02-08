
process DOWNLOAD_GET_TASKS {
    label 'low_cpu'
    input:
    val link

    output:
    path "tasks.tsv"

    script:
    """
    curl -X POST "$link" -o candidate_library_spectra.zip
    unzip candidate_library_spectra.zip

    get_tasks.py LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv tasks.tsv
    if [ ${params.testing} = false ]; then
        rm -rf LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv candidate_library_spectra.zip
    fi
    """
}

process GET_TASKS_FROM_FILE {
    publishDir params.out_dir, mode: 'move', flatten: true,include: 'tasks.tsv'

    label 'low_cpu'
    input:
    path file

    output:
    path "tasks.tsv"

    script:
    println(file)
    """
    get_tasks.py $file tasks.tsv
    if [ ${params.testing} = false ]; then
        rm -rf LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv candidate_library_spectra.zip
    fi
    """
}

process CREATE_PSMS{
    label 'low_cpu'
    publishDir "${params.out_dir}/psms", mode: 'move', flatten: true,include: '*_psms.tsv'

    input:
    val(task_id)

    output:
    val task_id
    path "*_psms.tsv"

    script:
    """
    curl 'https://proteomics2.ucsd.edu/ProteoSAFe/DownloadResult?task=${task_id}&view=view_result_list' --data-raw 'option=delimit&content=all&download=&entries=&query=' -o mzTab.zip
    unzip mzTab.zip -d extracted_files
    find extracted_files/ -type f -name "*.mzTab" -exec get_psm.py {} \\;
    parse.py psms.tsv ms_run_files.tsv ${task_id}_psms.tsv

    if [ ${params.testing} = false ]; then
        rm -rf extracted_files *.mzTab mzTab.zip ms_run_files.tsv *.mzXML *.mzML psms.tsv
    fi
    """
}

process COLLECT_SUCCESSFUL_FAILED_TASKS {
    label 'low_cpu'
    publishDir params.out_dir, mode: 'move', flatten: true, include: '*.tsv'

    input:
    val idList_all
    val idList_successful

    output:
    path "successful_tasks.tsv"
    path "failed_tasks.tsv"
    script:
    println(idList_all)
    """
    echo -e "${idList_successful.join('\n')}" > successful_tasks.tsv
    failed_tasks.py '${idList_all}' '${idList_successful}' failed_tasks.tsv
    """
}



