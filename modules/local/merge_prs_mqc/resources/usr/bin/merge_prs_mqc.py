#!/usr/bin/env -S uv run --script --no-cache
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pandas",
# ]
# ///

import sys
import pandas as pd

files = sys.argv[1:]

dfs = []
for f in files:
    df = pd.read_csv(f, sep='\t')
    dfs.append(df)

combined = pd.concat(dfs, ignore_index=True)
combined = combined.drop(columns=['#FID'], errors='ignore')
combined = combined.rename(columns={'IID': 'Sample'})

with open('prs_scores_mqc.tsv', 'w') as out:
    out.write("# id: 'prs-scores'\n")
    out.write("# section_name: 'PRS Scores'\n")
    out.write("# description: 'Normalised Polygenic Risk Score results per sample'\n")
    out.write("# plot_type: 'table'\n")
    combined.to_csv(out, sep='\t', index=False)
