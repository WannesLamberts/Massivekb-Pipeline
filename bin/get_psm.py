#!/usr/bin/env python3

from pyteomics.mztab import MzTab
import sys
import pandas as pd

def replace_ms_run(s, mapping):
    for ms_run, replacement in mapping.items():
        if ms_run in s:
            return s.replace(ms_run, replacement)
    return s
def main():
    file_path = sys.argv[1]
    mz = MzTab(file_path)

    two_columns = mz.spectrum_match_table[['spectra_ref', 'sequence']]
    data = two_columns.drop_duplicates(subset='sequence', keep='first').reset_index(drop=True)

    data[['ms_run', 'scan']] = data['spectra_ref'].str.split(':', expand=True)
    data['scan'] = data['scan'].str.replace('scan=', '', regex=False)
    data = data.drop(columns=['spectra_ref'])
    ms_run_to_file = {f"ms_run[{key}]": value.get('location') for key, value in mz.ms_runs .items()}

    data["ms_run"] = data["ms_run"].apply(lambda x: replace_ms_run(x, ms_run_to_file))
    data.to_csv('psms.tsv', sep='\t', index=False)

    ms_run_files = pd.Series(ms_run_to_file)
    ms_run_files.to_csv('ms_run_files.tsv', sep='\t', index=False, header=False)
main()

