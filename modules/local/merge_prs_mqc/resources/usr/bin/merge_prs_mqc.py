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
combined = combined.rename(columns={
    'SUM_Z': 'Z-score',
    'QC status': 'QC Status',
})
combined = combined[['Sample', 'Model', 'Z-score', 'QC Status', 'QC Comment', 'Model Alpha']]
combined.insert(0, 'Sample_Model', combined['Sample'] + '__' + combined['Model'])
combined = combined.sort_values(['Sample', 'Model']).reset_index(drop=True)

with open('prs_scores_mqc.tsv', 'w') as out:
    out.write("# id: 'prs-scores'\n")
    combined.to_csv(out, sep='\t', index=False)
