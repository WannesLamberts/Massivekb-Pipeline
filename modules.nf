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
    unzip candidate_library_spectra.zip
    """
}
process DOWNLOAD_MZTAB {
    label 'low_cpu'
    input:
    val link

    //output:
    //path "*.mzTab"

    script:
    println(params.out_dir)
    """
    download_mzTab.py "$link"
    """
}