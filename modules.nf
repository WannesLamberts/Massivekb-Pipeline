process DOWNLOAD_METADATA {
    label 'low_cpu'
    input:
    val link

    output:
    path "candidate_library_spectra.zip"

    script:
    """
    curl -X POST "$link" -o candidate_library_spectra.zip
    """
}
process EXTRACT_METADATA{
    label 'low_cpu'
    publishDir params.out_dir, pattern: "*.tsv"
    input:
    path zip

    output:
    path "*"

    script:
    """
    unzip $zip
    """
}
process DOWNLOAD_MZTAB {
    label 'low_cpu'
    input:
    val task_id

    output:
    tuple val(task_id),path("${task_id}.zip")

    script:
    """
    curl 'https://proteomics2.ucsd.edu/ProteoSAFe/DownloadResult?task=${task_id}&view=view_result_list' --data-raw 'option=delimit&content=all&download=&entries=&query=' -o ${task_id}.zip
    """
}
process EXTRACT_MZTAB{
    label 'low_cpu'

    input:
    tuple val(task_id),path(zip)

    output:
    tuple val(task_id),path("*.mzTab")

    script:
    """
    unzip $zip -d extracted_files
    find extracted_files/ -type f -name "*.mzTab" -exec mv {} . \\;

    # Conditionally delete if params.testing is true
    if [ ${params.testing} = false ]; then
        rm "\$(readlink -f $zip)" $zip
        rm -r extracted_files
    fi
    """
}



process DOWNLOAD_MZML_MZXML{
    label 'low_cpu'
    publishDir './results', mode: 'move', flatten: true,include: '*_psms.tsv'

    input:
    tuple val(task_id),path(mztab)

    output:
    val task_id
    path "*_psms.tsv"
    script:
    """
    get_psm.py $mztab
    wget --retry-connrefused --passive-ftp --tries=50 -i ms_run_files.tsv
    parse.py psms.tsv ${task_id}_psms.tsv
    if [ ${params.testing} = false ]; then
        rm "\$(readlink -f $mztab)" $mztab
        rm -rf ms_run_files.tsv *.mzXML *.mzML psms.tsv
    fi
    """
}

process CONCATENATE{
    label 'low_cpu'
    publishDir './results', mode: 'copy', flatten: true,include: 'combined.tsv'
    input:
    path files
    output:
    path "combined.tsv"
    script:
    """
    first=true
    for file in *_psms.tsv; do
    if [ "\$first" = true ]; then
        first=false
        echo "columns"
    else
        echo ""  # Adds a newline before every file except the first one
    fi
    cat "\$file"
    done > combined.tsv
    """
}

process TO_FILE{
    label 'low_cpu'
    publishDir params.out_dir, mode: 'move', flatten: true,include: 'succesfull_tasks.tsv'

    input:
    val idList

    output:
    file "succesfull_tasks"

    script:
    """
    # Here we are appending each ID to the tsv file
    echo -e "${idList.join('\n')}" > succesfull_tasks
    """
}


