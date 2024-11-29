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
    path "${task_id}.zip"

    script:
    """
    curl 'https://proteomics2.ucsd.edu/ProteoSAFe/DownloadResult?task=${task_id}&view=view_result_list' --data-raw 'option=delimit&content=all&download=&entries=&query=' -o ${task_id}.zip
    """
}
process EXTRACT_MZTAB{
    label 'low_cpu'
    input:
    path zip

    output:
    path "*.mzTab"

    script:
    """
    unzip $zip -d extracted_files
    mv extracted_files/mzTab/*.mzTab .
    rm -rf extracted_files
    """
}

process GET_PSM{
    label 'low_cpu'
    input:
    path mztab

    output:
    path "psms.tsv"
    path "ms_run_files.tsv"


    script:
    """
    get_psm.py $mztab
    """

}