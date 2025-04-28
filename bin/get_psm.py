#!/usr/bin/env python3

from pyteomics.mztab import MzTab
import sys
import pandas as pd

def replace_ms_run(ms_run, mapping):
    """
    This function uses the mapping msrun -> (massivekb location) and then returns the filename.

    Parameters:
    -----------
    ms_run: string
        The msrun to be mapped to filename.
        For example ms_run[1]

    mapping : dict
        Mapping from msrun to massivekb location.
        For example: {'ms_run[1]': 'file://MSV000080757/ccms_peak/RAW/20110823_EXQ3_TaGe_SA_BC8_3.mzML'}

    Returns:
    -----------
    -filename: string
        The filename of the mzMl or mzTab file.
        For example 20110823_EXQ3_TaGe_SA_BC8_3.mzML
    -dataset_name: string
        The name of the dataset. For exampls MSV000080757
    """
    location = mapping[ms_run]
    parts = location.split('/')
    filename = parts[-1]
    dataset_name = parts[2] if len(parts) > 2 else None

    return filename, dataset_name

def get_psm(file_path,task_id='0',create_ms_run_files=True):
    """
    This function extracts all the PSMs (Peptide Spectrum Matches) from an mzTab file.

    The output will be a file named psms.tsv. For each row in the mzTab file,
    the following columns will be generated: ['dataset', 'filename', 'scan', 'sequence', 'charge', 'mz']

    Additionally, the function produces an ms_run_files.tsv file, which contains the FTP links for downloading the mzML and mzXML files referenced in the mzTab file.
    These files will be used later in the parse.py script to enrich the PSM data with additional information.

    Parameters:
    -----------
    file_path : string
        The path to the mzTab file

    task_id : string,optional
        The task id from where the mzTab file was found.
    create_ms_run_files: bool,optional
        If true the function creates the ms_run_files.tsv file
    """
    #Parse mzTab file
    mz = MzTab(file_path)

    #Convert to dataframe
    df = mz.spectrum_match_table[['spectra_ref', 'sequence','charge','opt_global_Precursor']]
    #Drop duplicates sometimes multiple
    df = df.drop_duplicates(subset=['sequence','spectra_ref'], keep='first').reset_index(drop=True)

    #Split the spectra reference into two columns for example ms_run[1]:scan=23396 ->ms_run = ms_run[1], scan=23396
    df[['ms_run', 'scan']] = df['spectra_ref'].str.split(':', expand=True)
    df['scan'] = df['scan'].str.replace('scan=', '', regex=False)
    #Get a dictionary ms_run -> location on server, for example: {'ms_run[1]': 'file://MSV000080757/ccms_peak/RAW/20110823_EXQ3_TaGe_SA_BC8_3.mzML'}
    ms_run_to_file = {f"ms_run[{key}]": value.get('location') for key, value in mz.ms_runs .items()}
    #Map ms_run to download location on server
    df[["filename", "dataset"]] = df["ms_run"].apply(lambda x: pd.Series(replace_ms_run(x, ms_run_to_file)))
    df["task_id"] = task_id

    #output the psms dataframe
    df = df.rename(columns={'opt_global_Precursor': 'mz'})
    df[['task_id','dataset', 'filename', 'scan', 'sequence', 'charge', 'mz']].to_csv(task_id+'_psms.tsv', sep='\t', index=False,
                                                                           header=create_ms_run_files)
    #Output ms run files needed for peptides matches
    if create_ms_run_files:
        ms_run_files = pd.Series(ms_run_to_file)
        ms_run_files=ms_run_files.str.replace('file://', 'ftp://massive-ftp.ucsd.edu/z01/')
        ms_run_files.to_csv('ms_run_files.tsv', sep='\t', index=False, header=False)


file_path = sys.argv[1]
task_id=sys.argv[2]
create_ms_run_files = sys.argv[3].lower() == 'true'
get_psm(file_path,task_id,create_ms_run_files)
