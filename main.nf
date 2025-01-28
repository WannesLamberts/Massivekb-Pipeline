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
include { GET_PSM } from './modules.nf'
include { DOWNLOAD_MZML_MZXML } from './modules.nf'
include { COMPLETE_ROW } from './modules.nf'




workflow t{
    unique_ids = Channel.fromPath("test_data.tsv").splitCsv(header: true, sep: '\t').map(row -> row.proteosafe_task).unique()
    zips_mztab = DOWNLOAD_MZTAB(unique_ids)
    mztab = EXTRACT_MZTAB(zips_mztab)
    GET_PSM(mztab)
    massive_paths = GET_PSM.out[1].splitText()
    massive_paths = massive_paths.map { path -> path.replace('\n', '') }
    massive_paths.view()
    outp = DOWNLOAD_MZML_MZXML(massive_paths).collect()
    out2 = outp
    psms = GET_PSM.out[0]
    psm_rows = psms.splitCsv(sep: '\t')
    psm_rows_joined = psm_rows.join(out2,failOnMismatch: true)
    psm_rows_joined.first().view()
    //COMPLETE_ROW(psm_rows_joined)
}


process TEST_BATCH {
    label 'low_cpu'

    input:
    tuple val(id), val(sleep)

    output:
    path("${id}_${task.index}test.txt") // Unique filename per task

    script:
    """
    sleep ${sleep} # Simulating delay between batches
    cat << EOF > ${id}_${task.index}test.txt
    http://example.com/file_${id}_1
    http://example.com/file_${id}_2
    http://example.com/file_${id}_3
    EOF
    """
}

workflow tt{
    test = Channel.of([1, 10], [2, 1], [3, 1], [1, 1])
    out = TEST_BATCH(test)

    // Aggregate all emitted lines into a single list
    massive_paths = out.splitText()
                        .map { it.trim() }

    massive_paths.view()
}


workflow {
    mztab =  Channel.fromPath("oef.mzTab")
    GET_PSM(mztab)
    massive_paths = GET_PSM.out[1]
    massive_paths.view()
    //massive_paths = massive_paths.map { path -> path.replace('\n', '') }
    outp = DOWNLOAD_MZML_MZXML(massive_paths)
    //outp = outp.groupTuple()
    //out2 = outp.map{row -> [row[0],row[1].splitCsv(header: true, sep: '\t')]}
    //outp.first().view()


}

