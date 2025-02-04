
process GET_TASKS {
    label 'low_cpu'
    input:
    val link

    output:
    path "tasks.tsv"

    script:
    """
    curl -X POST "$link" -o candidate_library_spectra.zip
    unzip candidate_library_spectra.zip
    chmod +x get_tasks.py

    get_tasks.py LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv tasks.tsv
    if [ ${params.testing} = false ]; then
        rm -rf LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv candidate_library_spectra.zip
    fi
    """
}
process CREATE_PSMS{
    label 'low_cpu'
    publishDir params.out_dir, mode: 'move', flatten: true,include: '*_psms.tsv'

    input:
    val(task_id)

    output:
    val task_id
    path "*_psms.tsv"

    script:
    """
    curl 'https://proteomics2.ucsd.edu/ProteoSAFe/DownloadResult?task=${task_id}&view=view_result_list' --data-raw 'option=delimit&content=all&download=&entries=&query=' -o mzTab.zip
    unzip mzTab.zip -d extracted_files
    ls
    chmod +x get_psm.py
    find extracted_files/ -type f -name "*.mzTab" -exec get_psm.py {} \\;

    wget --retry-connrefused --passive-ftp --tries=50 -i ms_run_files.tsv
    chmod +x parse.py

    parse.py psms.tsv ${task_id}_psms.tsv

    if [ ${params.testing} = false ]; then
        rm -rf extracted_files *.mzTab mzTab.zip ms_run_files.tsv *.mzXML *.mzML psms.tsv
    fi
    """
}

process COLLECT_SUCCESFULL_TASKS{
    label 'low_cpu'
    publishDir params.out_dir, mode: 'move', flatten: true,include: 'succesfull_tasks.tsv'

    input:
    val idList

    output:
    file "succesfull_tasks.tsv"

    script:
    """
    echo -e "${idList.join('\n')}" > succesfull_tasks.tsv
    """
}



