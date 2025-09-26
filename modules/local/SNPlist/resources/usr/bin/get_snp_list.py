#!/usr/bin/env -S uv run --script --no-cache
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pandas",
# ]
# ///
import pandas as pd
from argparse import ArgumentParser



def positions_to_tsv(df, chr_colname, pos_colname, assembly_version, prefix):

    if assembly_version == "GRCh38":
        chr_prefix = "chr"
    else:
        chr_prefix = ""

    with open(f"{prefix}_snplist.list", 'w') as outfile:
        for index, row in df.iterrows():
            chrom = row[chr_colname]
            pos = row[pos_colname]

            try:
                if "chr" in chrom:
                    chr_prefix = ""
                    # For GRChr37 the chrom will be read as an int and which causes this error, which we can safely ignore
            except TypeError:
                pass

            tsv_fmt = f"{chr_prefix}{chrom}:{pos}-{pos}"
            if "None" in tsv_fmt:
                continue
            outfile.write(tsv_fmt + "\n")

def get_opts():
    p = ArgumentParser()
    p.add_argument("--scoring_file",
                   help="Custom scoring file, alternative for PGSID",
                   required=True)
    p.add_argument("--prefix",
                   help="Prefix for output files",
                   required=True)
    p.add_argument("--assembly_version",
                   help="Genome build version.",
                   required=True)

    return p.parse_args()

if __name__ == "__main__":
    args = get_opts()
    assembly_version = args.assembly_version # i.e., GRCh38/GRCh37

    file_content = pd.read_csv(args.scoring_file, sep='\t',comment='#')
    chr_colname = "hm_chr"
    pos_colname = "hm_pos"

    positions_to_tsv(file_content, chr_colname, pos_colname, assembly_version, args.prefix)
