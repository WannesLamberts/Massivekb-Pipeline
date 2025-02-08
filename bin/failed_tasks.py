#!/usr/bin/env python3
import sys


def failed(all_tasks, succesfull_tasks,out_file):
    all_ids = all_tasks.strip("[]").split(",")  # Remove square brackets and split by comma
    succesfull_ids = succesfull_tasks.strip("[]").split(",")  # Same for succesfull

    # Clean up any extra spaces or unwanted characters (e.g. quotes)
    all_ids = [id.strip().strip('"') for id in all_ids]
    succesfull_ids = [id.strip().strip('"') for id in succesfull_ids]

    # Get the IDs that are in 'all' but not in 'succesfull'
    failed_ids = list(set(all_ids) - set(succesfull_ids))

    # Write the failed IDs to a text file
    with open(out_file, "w") as f:
        for id in failed_ids:
            f.write(f"{id}\n")



failed(sys.argv[1], sys.argv[2], sys.argv[3])


