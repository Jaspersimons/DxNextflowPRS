#!/usr/bin/env python3


import pandas as pd
from sys import argv

base_stats_path = argv[1]
MAF_threshold = float(argv[2])
INFO_threshold = float(argv[3])
output = argv[4]

data = pd.read_csv(base_stats_path, sep='\t', engine="python")
data = data[
    (data["MAF"] > MAF_threshold) &  (data["INFO"] > INFO_threshold)
]

data.to_csv(output, compression='gzip',sep="\t", index=False)
