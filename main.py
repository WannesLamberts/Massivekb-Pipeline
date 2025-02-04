import csv
def split_dataset():

    #input_file = "../massivekb_dataset/LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv"
    output_file = "text.tsv"

    with open(input_file, 'r', encoding='utf-8') as infile:
        with open(output_file, 'w', encoding='utf-8', newline='') as outfile:
            reader = csv.reader(infile, delimiter='\t')
            writer = csv.writer(outfile, delimiter='\t')

            for i, row in enumerate(reader):
                if i < 100:
                    writer.writerow(row)
                else:
                    break

    print(f"First 100 rows saved to {output_file}")


import pandas as pd


def amount_tasks():
    input_file = "../massivekb_dataset/LIBRARY_CREATION_AUGMENT_LIBRARY_TEST-82c0124b-candidate_library_spectra-main.tsv"

    # Read the TSV file
    df = pd.read_csv(input_file, sep='\t')

    # Ensure the column name is correct
    column_name = "proteosafe_task"  # Adjust this if needed
    if column_name in df.columns:
        unique_values = df[column_name].nunique()
        print(f"Number of unique values in '{column_name}': {unique_values}")
    else:
        print(f"Column '{column_name}' not found. Available columns: {df.columns}")


# Call the function
amount_tasks()
