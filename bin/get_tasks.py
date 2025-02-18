#!/usr/bin/env python3
import sys

import pandas as pd

def get_tasks(input_file,output_file):
    """
    Gets all the unique tasks of the massivekb metadatafile located in input_file and outputs these in a .tsv file

    Parameters:
    -----------
    input_file: string
        The dataframe holding the tasks in the column proteosafe_task

    output_file : string
        The name of the output file.

    """
    df = pd.read_csv(input_file, sep='\t', usecols=["proteosafe_task"])

    # Extract unique values and remove NaN values in one step
    unique_values = df["proteosafe_task"].dropna().unique()

    # Save to a file using pandas' to_csv (faster than looping and writing manually)
    pd.Series(unique_values).to_csv(output_file, index=False, header=False)


input_file = sys.argv[1]
output_file = sys.argv[2]
get_tasks(input_file,output_file)