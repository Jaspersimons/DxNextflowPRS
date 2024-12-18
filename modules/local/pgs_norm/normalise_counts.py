#!/usr/bin/env python3

import argparse
import pandas as pd

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--PRS", help = "Table with PRS scores")
    parser.add_argument(
        "--mu",
        help="Population average for calculating Z-scores",
        required=True,
        type=float
    )
    parser.add_argument(
        "--SD",
        help="Population standard deviation for calculating Z-scores",
        required=True,
        type=float
    )
    parser.add_argument(
        "-o",
        help="Output file",
        required=True
    )

    return parser.parse_args()

def to_Z(score, mu, SD):
    return (int(score)-mu)/SD

if __name__ == "__main__":
    args = get_args()

    df = pd.read_csv(args.PRS, sep='\t')

    df["AVG_Z"] = (df['AVG'] - args.mu) * args.SD
    df["SUM_Z"] = (df['SUM'] - args.mu) * args.SD


    df.to_csv(args.o, sep='\t', index=False)
