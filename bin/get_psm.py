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

    """
    location = mapping[ms_run]
    filename = location.split('/')[-1]
    return filename

def get_psm(file_path,task_id='0'):
    """
    This function collects all the psm's from an mzTab file.

    The output of this funtion wil be a file psms.tsv
    For each row in the mzTab file the columns ['sequence','scan','filename','task_id'] will be created.

    The function also outputs ms_run_files.tsv which holds all the ftp links for downloading the required
    mzML and mzXML files in the mzTab files which will be used later in the parse.py script to add extra information to the psm's

    Parameters:
    -----------
    file_path : string
        The path to the mzTab file

    task_id : string,optional
        The task id from where the mzTab file was found.
    """
    #Parse mzTab file
    mz = MzTab(file_path)

    #Convert to dataframe
    df = mz.spectrum_match_table[['spectra_ref', 'sequence']]
    #Drop duplicates sometimes multiple
    df = df.drop_duplicates(subset=['sequence','spectra_ref'], keep='first').reset_index(drop=True)

    #Split the spectra reference into two columns for example ms_run[1]:scan=23396 ->ms_run = ms_run[1], scan=23396
    df[['ms_run', 'scan']] = df['spectra_ref'].str.split(':', expand=True)
    df['scan'] = df['scan'].str.replace('scan=', '', regex=False)
    #Get a dictionary ms_run -> location on server, for example: {'ms_run[1]': 'file://MSV000080757/ccms_peak/RAW/20110823_EXQ3_TaGe_SA_BC8_3.mzML'}
    ms_run_to_file = {f"ms_run[{key}]": value.get('location') for key, value in mz.ms_runs .items()}

    #Map ms_run to download location on server
    df["filename"] = df["ms_run"].apply(lambda x: replace_ms_run(x, ms_run_to_file))
    df["task_id"] = task_id
    #Output peptide matches to tsv file
    df[['sequence','scan','filename','task_id']].to_csv('psms.tsv', sep='\t', index=False, header=True)
    #Output ms run files needed for peptides matches
    ms_run_files = pd.Series(ms_run_to_file)
    ms_run_files=ms_run_files.str.replace('file://', 'ftp://massive.ucsd.edu/z01/')
    ms_run_files.to_csv('ms_run_files.tsv', sep='\t', index=False, header=False)


file_path = sys.argv[1]
task_id=sys.argv[2]
get_psm(file_path,task_id)
