#!/usr/bin/env python3

import requests
import gzip
import pandas as pd
import io
from argparse import ArgumentParser

from sys import argv



def get_positions_url(PGS_id, assembly_version):
    url = "https://www.pgscatalog.org/rest/score/{}"
    response = requests.get(url.format(PGS_id))
    data = response.json()

    positions_url = data['ftp_harmonized_scoring_files'][assembly_version]['positions']
    return positions_url

def get_positions(url):
    response = requests.get(url)

    with gzip.GzipFile(fileobj=io.BytesIO(response.content)) as gz:
        file_content = gz.read().decode('utf-8')

        lines =  [line.split("\t") for line in file_content.split("\n") if not line.startswith('#')]
        return pd.DataFrame(lines[1:], columns=lines[0])

def positions_to_tsv(df, chr_colname, pos_colname, assembly_version):

    if assembly_version == "GRCh38":
        chr_prefix = "chr"
    else:
        chr_prefix = ""

    for index, row in df.iterrows():
        chrom = row[chr_colname]
        pos = row[pos_colname]

        tsv_fmt = f"{chr_prefix}{chrom}:{pos}-{pos}"
        if "None" in tsv_fmt:
           continue
        print(tsv_fmt)


def get_opts():
    p = ArgumentParser()
    p.add_argument("--PGSID",
                   help="PGSC ID to to retrieve",
                   required=False)
    p.add_argument("--scoring_file",
                   help="Custom scoring file, alternative for PGSID",
                   required=False)
    p.add_argument("--assembly_version",
                   help="Genome build version.",
                   required=True)

    return p.parse_args()

if __name__ == "__main__":
    args = get_opts()
    assembly_version = args.assembly_version # i.e., GRCh38/GRCh37

    if args.PGSID is not None:

        positions_url = get_positions_url(args.PGSID, assembly_version)
        file_content = get_positions(positions_url)

        chr_colname = "hm_chr"
        pos_colname = "hm_pos"


    else:
        file_content = pd.read_csv(args.scoring_file, sep='\t',comment='#')
        chr_colname = "chr_name"
        pos_colname = "chr_position"

    positions_to_tsv(file_content, chr_colname, pos_colname, assembly_version)
