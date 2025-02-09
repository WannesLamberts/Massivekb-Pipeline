#!/usr/bin/env python3

from pyteomics.mztab import MzTab
import sys
import pandas as pd

def replace_ms_run(s, mapping):
    for ms_run, replacement in mapping.items():
        if ms_run in s:
            location = s.replace(ms_run, replacement)
            filename = location.split('/')[-1]  # Extract filename from location
            return filename
    return s


def main():
    file_path = sys.argv[1]

    #Parse mzTab file
    mz = MzTab(file_path)

    #Convert to dataframe
    df = mz.spectrum_match_table[['spectra_ref', 'sequence']]
    #Drop duplicates sometimes multiple
    df = df.drop_duplicates(subset='sequence', keep='first').reset_index(drop=True)

    #split the spectra reference into two columns for example ms_run[1]:scan=23396 ->ms_run = ms_run[1], scan=23396
    df[['ms_run', 'scan']] = df['spectra_ref'].str.split(':', expand=True)
    df['scan'] = df['scan'].str.replace('scan=', '', regex=False)
    #Get a dictionary ms_run -> location on server, for example: {'ms_run[1]': 'file://MSV000080757/ccms_peak/RAW/20110823_EXQ3_TaGe_SA_BC8_3.mzML'}
    ms_run_to_file = {f"ms_run[{key}]": value.get('location') for key, value in mz.ms_runs .items()}

    #map ms_run to download location on server
    df["filename"] = df["ms_run"].apply(lambda x: replace_ms_run(x, ms_run_to_file))
    #output peptide matches to tsv file
    df[['sequence','scan','filename']].to_csv('psms.tsv', sep='\t', index=False, header=False)
    #output ms run files needed for peptides matches
    ms_run_files = pd.Series(ms_run_to_file)
    ms_run_files=ms_run_files.str.replace('file://', 'ftp://massive.ucsd.edu/z01/')
    ms_run_files.to_csv('ms_run_files.tsv', sep='\t', index=False, header=False)

main()

