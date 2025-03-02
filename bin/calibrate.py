#!/usr/bin/env python3

import os
import sys

import pandas as pd
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from sklearn import linear_model

def get_calibration_peptides(df, calibration_df=None):
    """
    Retrieves a dictionary of calibration peptides and their corresponding iRT (indexed Retention Time) values.

    Author:
    -----------
    Ceder Dens

    Parameters:
    -----------
    df : pandas.DataFrame
        The main DataFrame containing peptide data.

    calibration_df : pandas.DataFrame, optional
        A DataFrame containing reference peptides and their known iRT values. If provided, the function
        will return calibration peptides that overlap between `df` and `calibration_df`. If not provided,
        a default set of iRT calibration peptides will be used.

    Returns:
    --------
    dict
        A dictionary where the keys are peptide sequences (str) and the values are the corresponding iRT values (float).
        If `calibration_df` is provided, the dictionary will contain peptides from the overlap of `df` and `calibration_df`.
        Otherwise, a predefined set of calibration peptides and iRT values is returned.
    """
    if calibration_df is None:
        return {
            "TFAHTESHISK": -15.01839514765834,
            "ISLGEHEGGGK": 0.0,
            "LSSGYDGTSYK": 12.06522819926421,
            "LYSYYSSTESK": 31.058963905737304,
            "GFLDYESTGAK": 63.66113155016407,
            "HDTVFGSYLYK": 72.10102416227504,
            "ASDLLSGYYIK": 90.51605846673961,
            "GFVIDDGLITK": 100.0,
            "GASDFLSFAVK": 112.37148254946804,
        }
    else:
        overlap = df.merge(calibration_df, how="inner", left_on="sequence", right_on="PeptideModSeq")
        return {
            k: v for k, v in zip(overlap["PeptideModSeq"], overlap["Prosit_RT"])
        }

def calibrate_to_iRT(df,calibration_df=None,seq_col="sequence",rt_col="RT",
    irt_col="iRT",plot=False,filename=None,take_median=True,):
    """
    Calibrates the retention times in a DataFrame to indexed Retention Time (iRT) values using a set of calibration peptides.

    Parameters:
    -----------
    df : pandas.DataFrame
        The input DataFrame containing peptide sequences and their respective retention times

    calibration_df : pandas.DataFrame, optional
        A DataFrame containing calibration peptides and their known iRT values. If not provided, a predefined
        set of calibration peptides will be used.

    seq_col : str, optional
        The column name in `df` that contains the peptide sequences. Default is "Modified sequence".

    rt_col : str, optional
        The column name in `df` that contains the retention time values. Default is "Retention time".

    irt_col : str, optional
        The column name where the predicted iRT values will be stored in `df`. Default is "iRT".

    plot : bool, optional
        If True, a scatter plot of the original Retention time values vs. iRT values will be generated along with the fitted regression line.

    filename : str, optional
        If provided, the function will print the number of calibration peptides found in the DataFrame. Useful for logging or debugging.

    take_median : bool, optional
        If True, the median retention time for each calibration peptide will be used. Otherwise, the first occurrence of the Retention time value will be used.

    Returns:
    --------
    pandas.DataFrame or None
        The input DataFrame with an additional column containing the calibrated iRT values.
        If fewer than two calibration peptides are found in the input data, the function returns `None`.

    Process:
    --------
    1. The function first retrieves a dictionary of calibration peptides and their corresponding iRT values.
    2. It loops through the calibration peptides and retrieves the corresponding Retention time values from the input DataFrame.
    3. If `take_median` is True, it uses the median Retention time value for each peptide; otherwise, it uses the first occurrence.
    4. The old Retention time values and iRT values are then used to fit a linear regression model.
    5. The model is used to predict iRT values for all peptides in the input DataFrame.
    6. If `plot` is True, a scatter plot of calibration points and the regression line is displayed.
    7. The function returns the input DataFrame with an additional column for iRT values, or `None` if calibration fails.
    """

    # Get calibration peptides and their corresponding iRT values
    calibration_peptides = get_calibration_peptides(df, calibration_df)
    old_rt = []
    cal_rt = []

    # Loop through each calibration peptide
    for pep, iRT in calibration_peptides.items():
        # Filter the DataFrame to get rows corresponding to the current peptide sequence
        pep_df = df[df[seq_col] == pep]
        if len(pep_df) > 0:
            # Use the median or first occurrence of the RT value based on the `take_median` flag
            if take_median:
                old = np.median(df[df[seq_col] == pep][rt_col])
            else:
                old = df[df[seq_col] == pep][rt_col].iloc[0]

            old_rt.append(old)
            cal_rt.append(iRT)
    # Log the number of calibration peptides found if `filename` is provided
    if filename is not None:
        print(
            f"{filename} had {len(old_rt)}/{len(calibration_peptides)} calibration peptides"
        )
    # If fewer than two calibration peptides are found, return None (unable to perform calibration)
    if len(old_rt) < 2:
        print("NOT ENOUGH CAL PEPTIDES FOUND")
        return None

    # Fit a linear regression model using the original RT values and the iRT values
    regr = linear_model.LinearRegression()
    regr.fit(np.array(old_rt).reshape(-1, 1), np.array(cal_rt).reshape(-1, 1))

    # Predict iRT values for all peptides in the input DataFrame
    df[irt_col] = regr.predict(df[rt_col].values.reshape(-1, 1))

    # Plot the calibration points and the fitted regression line if `plot=True`
    if plot:
        plt.scatter(old_rt, cal_rt, label="calibration points")
        plt.plot(
            range(int(min(old_rt) - 5), int(max(old_rt) + 5)),
            regr.predict(
                np.array(
                    range(int(min(old_rt) - 5), int(max(old_rt) + 5))
                ).reshape(-1, 1)
            ),
            label="fitted regressor",
        )
        plt.legend()
        plt.show()

    return df
def calibrate_file(file_path, calibration_df):
    """
    calibrates the file in the directory.
    the file holds a dataframe which has a column filename.
    The calibrating will be run on each filename.

    Parameters:
    -----------
    file_path : string
        The path of the tsv file to be calibrated


    out_dir : string
        The name of the directory where the calibration results will be saved.

    calibration_df : pandas.DataFrame
        The dataframe which will be used as reference for the calibration.

    """
    columns = ['task_id','dataset', 'filename', 'scan', 'sequence', 'charge', 'mz','RT']
    df = pd.read_csv(file_path, sep='\t', header=None, names=columns)

    calibrated_df = df.groupby('filename').apply(
        lambda group: calibrate_to_iRT(group, calibration_df, 'sequence', 'RT'),
        include_groups=False
    ).reset_index()
    calibrated_df = calibrated_df.drop('level_1', axis=1)
    output_file_path =  os.path.dirname(file_path)+os.path.splitext(os.path.basename(file_path))[0]+"_calibrated.tsv"
    calibrated_df.to_csv(output_file_path, sep='\t', index=False,header=False)

psms_path = sys.argv[1]
chronologer_loc = sys.argv[2]
chronologer = pd.read_csv(chronologer_loc, sep='\t')
calibrate_file(psms_path, chronologer)


