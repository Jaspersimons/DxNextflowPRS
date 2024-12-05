#!/usr/bin/env python3

import requests
import gzip
import pandas as pd
import io
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

        return [line.split("\t") for line in file_content.split("\n") if not line.startswith('#')]

def positions_to_tsv(file_content, assembly_version):

    df = pd.DataFrame(file_content[1:], columns=file_content[0])

    if assembly_version == "GRCh38":
        chr_prefix = "chr"
    else:
        chr_prefix = ""

    for index, row in df.iterrows():
        chrom = row["hm_chr"]
        pos = row["hm_pos"]
        tsv_fmt = f"{chr_prefix}{chrom}:{pos}-{pos}"
        if "None" in tsv_fmt:
           continue
        print(tsv_fmt)

if __name__ == "__main__":
    PGS_id = argv[1] # "PGS000001"
    assembly_version = argv[2] #"GRCh38"

    positions_url = get_positions_url(PGS_id, assembly_version)

    file_content = get_positions(positions_url)

    positions_to_tsv(file_content, assembly_version)
