#!/usr/bin/env python3

from sys import argv
from argparse import ArgumentParser
from pathlib import Path

p = ArgumentParser()
p.add_argument("meta_id")
p.add_argument("path_prefix")
p.add_argument("--chrom", default = "", required=False)
p.add_argument("--format", default = "pfile", required=False)
opts = p.parse_args()


prefix_clean = opts.path_prefix.replace("[","").replace("]","")
prefix_clean = prefix_clean.replace(Path(prefix_clean).suffix, "")

with open("output_samplesheet.csv",'w') as samplesheet:
    samplesheet.write("sampleset,path_prefix,chrom,format\n")
    samplesheet.write(f"{opts.meta_id},{prefix_clean},{opts.chrom},{opts.format}\n")
