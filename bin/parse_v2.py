#!/usr/bin/env python3
import os
import sys
import pandas as pd
from pyteomics.mzml import MzML
import re
import subprocess
from pyteomics.mzxml import MzXML

import time

def parse_mzML(file, data):
    with MzML(file) as mz:  # Automatically closes the file after processing
        for spec in mz:
            ret = spec["scanList"]["scan"][0]["scan start time"]
            scan_nr = str(re.search(r'scan=(\d+)', spec["id"]).group(1))
            data.append({'filename': file, 'scan': scan_nr, 'RT': ret})

def parse_mzXML(file, data):
    with MzXML(file) as mz:  # Automatically closes the file after processing
        for spec in mz:
            scan_nr = spec["num"]
            ret = spec["retentionTime"]
            data.append({'filename': file, 'scan': scan_nr, 'RT': ret})


def main():
    ms_run_files = sys.argv[2]
    data = []

    with open(ms_run_files, "r") as file:
        for line in file:
            url = line.strip()
            subprocess.run(["curl","-O",url], check=True)
            filename = os.path.basename(url)
            if filename.endswith(".mzML"):
                parse_mzML(filename,data)
            elif filename.endswith(".mzXML"):
                parse_mzXML(filename,data)
            os.remove(filename)
    #Convert required information to a pandas dataframe
    df = pd.DataFrame(data)
    #Read the uncompleted psms into a dataframe
    file_path = sys.argv[1]
    df_psms= pd.read_csv(file_path, sep='\t')
    df_psms['scan'] = df_psms['scan'].astype(str)

    #Right join the two dataframes on filename and scan to get the completed psms
    result = pd.merge(df, df_psms, how='right', on=['filename','scan'])
    output_filename = sys.argv[3]
    result.to_csv(output_filename, sep='\t', index=False, header=True)


main()

