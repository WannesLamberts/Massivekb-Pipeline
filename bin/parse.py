#!/usr/bin/env python3
import os
import sys
import pandas as pd
from pyteomics.mzml import MzML
import re


def main():
    # List mzML files in the current directory
    mzMLfiles = [f for f in os.listdir() if f.endswith(".mzML")]

    # Prepare a list to hold the data
    data = []

    # Iterate through the mzML files and extract information
    for f in mzMLfiles:
        mz = MzML(f)
        for spec in mz:
            ret = spec["scanList"]["scan"][0]["scan start time"]
            scan_nr = str(re.search(r'scan=(\d+)', spec["id"]).group(1))
            data.append({'ms_run': f, 'scan': scan_nr, 'RT': ret})

    # Convert the list of dictionaries into a pandas DataFrame
    df = pd.DataFrame(data)
    file_path = "psms.tsv"
    df2 = pd.read_csv(file_path, sep='\t')
    df2['scan'] = df2['scan'].astype(str)


    df2['ms_run'] = df2['ms_run'].str.split('/').str[-1]
    result = pd.merge(df, df2, how='right', on=['ms_run','scan'])
    print(result)


main()

