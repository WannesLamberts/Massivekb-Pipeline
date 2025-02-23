#!/usr/bin/env python3

import sys

import pandas as pd

file = sys.argv[1]
# Read the TSV file
df = pd.read_csv(file, sep='\t')

# Save as Parquet
df.to_parquet('dataset.parquet', engine='pyarrow')