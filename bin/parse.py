#!/usr/bin/env python3
import os
import sys
import pandas as pd
from pyteomics.mzml import MzML
import re

from pyteomics.mzxml import MzXML


def main():
    #Get all mzML files in current directory
    mzMLfiles = [f for f in os.listdir() if f.endswith(".mzML")]
    mzXMLfiles = [f for f in os.listdir() if f.endswith(".mzXML")]
    data = []

    #for every mzML file parse required information for psm
    for f in mzMLfiles:
        mz = MzML(f)
        for spec in mz:
            ret = spec["scanList"]["scan"][0]["scan start time"]
            scan_nr = str(re.search(r'scan=(\d+)', spec["id"]).group(1))
            data.append({'filename': f, 'scan': scan_nr, 'RT': ret})

    for f in mzXMLfiles:
        mzXML = MzXML(f)
        for spec in mzXML:
            scan_nr=spec["num"]
            ret = spec["retentionTime"]
            data.append({'filename': f, 'scan': scan_nr, 'RT': ret})
    #Convert required information to a pandas dataframe
    df = pd.DataFrame(data)
    #Read the uncompleted psms into a dataframe
    file_path = sys.argv[1]
    df_psms= pd.read_csv(file_path, sep='\t')
    df_psms['scan'] = df_psms['scan'].astype(str)

    #Right join the two dataframes on filename and scan to get the completed psms
    result = pd.merge(df, df_psms, how='right', on=['filename','scan'])
    output_filename = sys.argv[2]
    result.to_csv(output_filename, sep='\t', index=False, header=True)

main()

