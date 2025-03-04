
process DOWNLOAD_GET_TASKS {
    /*
      This process will download the massiveKB tsv metadata file and collects the unique tasks
      located in the proteosafe_task column.
      The process will output a task.tsv file holding these unique tasks.
      If the param publish_tasks is set to 'True' the tasks.tsv file will be put in the out_dir folder.
    */
    label 'low_cpu'
    publishDir params.out_dir, mode: 'move', flatten: true,include: 'tasks.tsv'

    input:
    val link

    output:
    path "tasks.tsv"

    script:
    """
    # Download and unzip the metadata.
    curl -X POST "$link" -o candidate_library_spectra.zip
    unzip candidate_library_spectra.zip

    # Get the unique tasks and write them in tasks.tsv
    get_tasks.py LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv tasks.tsv

    # Delete the big metadata and zip since it is no longer needed.
    if [ ${params.testing} = false ]; then
        rm -rf LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv candidate_library_spectra.zip
    fi
    """
}

process GET_TASKS_FROM_FILE {
    /*
      This process will use the massiveKB metadata file to collect the unique tasklocated in the proteosafe_task column.
      (so it doesn't download it like DOWNLOAD_GET_TASKS).
      The process will output a task.tsv file holding these unique tasks.
      The process will move tasks.tsv to the out_dir location
    */
    publishDir params.out_dir, mode: 'move', flatten: true,include: 'tasks.tsv'
    label 'low_cpu'
    input:
    path file

    output:
    path "tasks.tsv"

    script:
    """
    # Get the unique tasks and write them in tasks.tsv
    get_tasks.py $file tasks.tsv

    # Delete the big metadata and zip since it is no longer needed.
    if [ ${params.testing} = false ]; then
        rm -rf LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv candidate_library_spectra.zip
    fi
    """
}
process CREATE_PSMS{
    /*
    This process downloads the mzTab of a task.
    Collects all the psms listed in the mztab file.
    Parses the mzML and mzXML files to get more information about the psms
    Right joins the psms and the extra information to get a TSV file {task_id}_psms.tsv
    The columns in this tsv file are ['dataset', 'filename', 'scan', 'sequence', 'charge', 'mz','RT']
    */
    label 'low_cpu'
    publishDir "${params.out_dir}/psms", mode: 'move', flatten: true,include: '*_psms_complete.tsv'

    input:
    val(task_id)

    output:
    val task_id
    path "*_psms_complete.tsv"

    script:
    """
    #Download and unzip the mzTab file.
    curl 'https://proteomics2.ucsd.edu/ProteoSAFe/DownloadResult?task=${task_id}&view=view_result_list' --data-raw 'option=delimit&content=all&download=&entries=&query=' -o mzTab.zip
    unzip mzTab.zip -d extracted_files

    #Gets the psms and a file containing all the links to the mzML and mzXML files for the mzTab file.
    find extracted_files/ -type f -name "*.mzTab" -exec bash -c 'get_psm.py "\$0" "\$1" True' {} ${task_id} \\;

    #If no mztab file is found the process stops with exit code 186.
    if ! find extracted_files -type f -name "*.mzTab" | grep -q .; then
        exit 186
    fi

    #If no ms_run_files is found (meaning that something went wrong in get_psm.py) exit with code 51.
    if ! find . -type f -name "ms_run_files.tsv" | grep -q .; then
    exit 51
    fi

    #parse the mzML and mzXML files and use the information to create the complete psms.
    parse.py ${task_id}_psms.tsv ms_run_files.tsv ${task_id}_psms_complete.tsv

    #delete files that are not longer needed.
    if [ ${params.testing} = false ]; then
        rm -rf extracted_files *.mzTab mzTab.zip ms_run_files.tsv *.mzXML *.mzML ${task_id}_psms.tsv
    fi
    """
}
process CREATE_PSMS_SIMPLE{
    /*
    This process downloads the mzTab of a task.
    Collects all the psms listed in the mztab file and information.
    The columns in this tsv file are ['dataset', 'filename', 'scan', 'sequence', 'charge', 'mz']
    */
    label 'low_cpu'
    publishDir "${params.out_dir}/psms", mode: 'move', flatten: true,include: '*_psms.tsv'

    input:
    val(task_id)

    output:
    val task_id
    path "*_psms.tsv"

    script:
    """
    #Download and unzip the mzTab file.
    curl 'https://proteomics2.ucsd.edu/ProteoSAFe/DownloadResult?task=${task_id}&view=view_result_list' --data-raw 'option=delimit&content=all&download=&entries=&query=' -o mzTab.zip
    unzip mzTab.zip -d extracted_files

    #Gets the psms and a file containing all the links to the mzML and mzXML files for the mzTab file.
    find extracted_files/ -type f -name "*.mzTab" -exec bash -c 'get_psm.py "\$0" "\$1" False' {} ${task_id} \\;

    #If no mztab file is found the process stops with exit code 186.
    if ! find extracted_files -type f -name "*.mzTab" | grep -q .; then
        exit 186
    fi

    #If no psms.tsv file is found (meaning that something went wrong in get_psm.py) exit with code 51.
    if ! find . -type f -name "${task_id}_psms.tsv" | grep -q .; then
    exit 51
    fi

    #delete files that are not longer needed.
    if [ ${params.testing} = false ]; then
        rm -rf extracted_files *.mzTab mzTab.zip
    fi
    """
}
process COLLECT_SUCCESSFUL_TASKS {
    /*
     This process will collect the succesfull task_id's and puts them into a tsv file.
    */
    label 'low_cpu'
    publishDir params.out_dir, mode: 'move', flatten: true, include: '*.tsv'

    input:
    val idList_successful

    output:
    path "successful_tasks.tsv"
    script:
    """
    echo -e "${idList_successful.join('\n')}" > successful_tasks.tsv
    """
}


process TO_PARQUET {
    /*
    This process combines all TSV files in the specified directory into a single merged.tsv file, adding the provided column names as headers.
    Next, it converts merged.tsv into dataset.parquet.
    Finally, the merged.tsv file is deleted to optimize storage.
    */
    publishDir params.out_dir, mode: 'move', flatten: true, include: '*.parquet'

    input:
    path input_files  // input_files should be a list of the TSV files generated earlier
    val cols
    output:
    path 'dataset.parquet'  // This will be the concatenated output

    script:
    """
    echo -e "${cols.join('\\t')}" > merged.tsv
    for file in ${input_files}; do
        cat "\$file" >> merged.tsv
        echo "" >> merged.tsv  # Ensuring a newline after each file
    done
    to_parquet.py merged.tsv
    rm merged.tsv
    """
}

process MERGE {
    /*
    This process merges all the tsv files of the given directory into big merged.tsv file
    It will also put the column names provided at the top of the file.
    */
    publishDir params.out_dir, mode: 'move', flatten: true, include: 'merged.tsv'

    input:
    path input_files
    val cols
    output:
    path 'merged.tsv'

    script:
    """
    echo -e "${cols.join('\\t')}" > merged.tsv
    for file in ${input_files}; do
        cat "\$file" >> merged.tsv
        echo "" >> merged.tsv  # Ensuring a newline after each file
    done
    """
}


process CALIBRATE {
    /*
    This process calibrates the retention times for all PSM files in the specified directory.
    It uses the Chronologer dataset as a reference point
    and applies linear regression to predict retention times.
     */
    publishDir "${params.out_dir}/psms_calibrated", mode: 'move', flatten: true, include: '*calibrated.tsv'

    input:
    path input_file
    path chronologer
    output:
    path '*calibrated.tsv'

    script:
    """
    calibrate.py ${input_file} ${chronologer}
    """
}