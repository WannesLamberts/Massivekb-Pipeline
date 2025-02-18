#!/usr/bin/env python3
import os
import sys
import pandas as pd
from pyteomics.mzml import MzML
import re
import subprocess
from pyteomics.mzxml import MzXML

import time

def parse_mzML(file_path, data):
    """
    This function collects the following information out if a mzML file:
    retention time
    It creates a row for each scan in the mzML file and puts these rows into the data vector
    also  scan_nr and filename are added for joining later with the psms.

    Parameters:
    -----------
    file_path : string
        The path to the mzML file

    data : vector
        A vector holding a row for each scan
    """
    with MzML(file_path) as mz:  # Automatically closes the file after processing
        for spec in mz:
            ret = spec["scanList"]["scan"][0]["scan start time"]
            scan_nr = str(re.search(r'scan=(\d+)', spec["id"]).group(1))
            data.append({'filename': file_path, 'scan': scan_nr, 'RT': ret})

def parse_mzXML(file, data):
    """
    This function collects the following information out if a mzXML file:
    retention time
    It creates a row for each scan in the mzXML file and puts these rows into the data vector
    also  scan_nr and filename are added for joining later with the psms.

    Parameters:
    -----------
    file_path : string
        The path to the mzML file

    data : vector
        A vector holding a row for each scan
    """
    with MzXML(file) as mz:  # Automatically closes the file after processing
        for spec in mz:
            scan_nr = spec["num"]
            ret = spec["retentionTime"]
            data.append({'filename': file, 'scan': scan_nr, 'RT': ret})


def parse(psms_path,ms_run_files,output_filename):
    """
    This function downloads all the mzML and mzXML files,
    gets all the scans out of them and then joins them with the psms to get the complete rows

    It outputs the completed dataframe as a tsv file.

    Parameters:
    -----------
    psms_path : string
        The path to the psms tsv file holding all the psms from the mzTab file.

    ms_run_files : string
        A list of mzML and mzXML ftp links to download.

    output_filename : string
        The name of the output file.
    """
    data = []

    with open(ms_run_files, "r") as file:
        for line in file:
            url = line.strip()
            try:
                #Get the mzML or mzXML file from massivekb
                subprocess.run(['wget', '--retry-connrefused', '--passive-ftp', '--tries=50', url],check=True)
                #subprocess.run(['curl', url], check=True)
            except Exception as e:
                sys.exit(58)

            filename = os.path.basename(url)
            #If it is a mzML file parse it with parse_mzML
            if filename.endswith(".mzML"):
                parse_mzML(filename,data)
            #If it is a mzXML file parse it with parse_mzML
            elif filename.endswith(".mzXML"):
                parse_mzXML(filename,data)
            os.remove(filename)
    #Convert required information to a pandas dataframe
    df = pd.DataFrame(data)
    #Read the uncompleted psms into a dataframe
    df_psms= pd.read_csv(psms_path, sep='\t')
    df_psms['scan'] = df_psms['scan'].astype(str)

    #Right join the two dataframes on filename and scan to get the completed psms
    result = pd.merge(df, df_psms, how='right', on=['filename','scan'])
    output_filename = sys.argv[3]
    result.to_csv(output_filename, sep='\t', index=False, header=False)


psms_path = sys.argv[1]
ms_run_files = sys.argv[2]
output_filename = sys.argv[3]
parse(psms_path, ms_run_files,output_filename)

