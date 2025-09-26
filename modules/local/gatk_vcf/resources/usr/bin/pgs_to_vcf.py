#!/usr/bin/env -S uv run --script --no-cache
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "argparse",
#     "pathlib",
# ]
# ///
import argparse, csv, sys
from pathlib import Path

def parse_args():
    p = argparse.ArgumentParser(
        description="Convert a PGS Catalog scoring CSV/TSV to a VCF (REF=other_allele, ALT=effect_allele)."
    )
    p.add_argument("input", help="Input PGS scoring file (tab-delimited)")
    p.add_argument("output", help="Output VCF path ('-' for stdout)")
    p.add_argument("--pgsid", help="Override PGS ID for header/INFO (falls back to value parsed from metadata)")
    p.add_argument("--genome-build", help="Override genome build for header (e.g. GRCh37/GRCh38)")
    return p.parse_args()

def read_meta(path):
    meta = {}
    with open(path, "r", newline="") as file_header:
        for line in file_header:
            if not line.startswith("#"):  # stop at first non-# (the header line)
                break
            if line.startswith("###"):    # human-readable banner -> ignore
                continue
            if "=" in line:
                key, val = line.strip()[1:].split("=", 1)
                meta[key.strip()] = val.strip()
    return meta

def main():
    args = parse_args()
    meta = read_meta(args.input)
    pgsid = args.pgsid or meta.get("pgs_id", "PGS_UNKNOWN")
    build = args.genome_build or meta.get("genome_build", "unknown")

    # Open IO
    out = sys.stdout if args.output == "-" else open(args.output, "w", newline="")
    with open(args.input, "r", newline="") as fh, out as oh:
        # Skip metadata lines
        for line in fh:
            if not line.startswith("#"):
                header = line.rstrip("\n")
                break
        # Dialect: TSV (PGS scoring files are tab-delimited)
        cols = header.split("\t")
        reader = csv.DictReader([header] + fh.readlines(), delimiter="\t")

        # collect contigs to emit header contig lines later
        contigs = set()

        # Write VCF header
        oh.write("##fileformat=VCFv4.2\n")
        oh.write(f"##source=PGS_Catalog_to_VCF\n")
        oh.write(f"##pgs_id={pgsid}\n")
        oh.write(f"##reference={build}\n")
        oh.write('##INFO=<ID=PGSID,Number=1,Type=String,Description="PGS score identifier">\n')
        oh.write('##INFO=<ID=EFFECT_WEIGHT,Number=1,Type=Float,Description="Effect weight from PGS file">\n')
        oh.write('##INFO=<ID=EAF,Number=1,Type=Float,Description="Effect allele frequency (allelefrequency_effect)">\n')
        oh.write('##INFO=<ID=HM_SOURCE,Number=1,Type=String,Description="Harmonization source (hm_source)">\n')
        oh.write('##INFO=<ID=HM_MATCH,Number=1,Type=String,Description="Harmonization match flags chr/pos">\n')

        # Peek through to gather contigs (we need to iterate twice or buffer)
        rows = list(reader)
        for r in rows:
            chrom = (r.get("hm_chr") or r.get("chr_name") or "").strip()
            if chrom:
                if build.lower() == "grch38" and 'chr' not in chrom:
                    
                    chrom = f"chr{chrom}"
                contigs.add(str(chrom))
        for c in sorted(contigs, key=lambda x: (x.lstrip("chr") if isinstance(x, str) else x)):
            oh.write(f"##contig=<ID={c}>\n")

        oh.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n")

        # Emit records
        for i, r in enumerate(rows, start=1):
            # Choose harmonized coords if available, else original
            hm_chr = (r.get("hm_chr") or "").strip()
            hm_pos = (r.get("hm_pos") or "").strip()
            chr_name = (r.get("chr_name") or "").strip()
            chr_pos  = (r.get("chr_position") or "").strip()

            chrom = hm_chr or chr_name
            pos = hm_pos or chr_pos

            if build.lower() == "grch38" and 'chr' not in chrom:
                chrom = f"chr{chrom}"

            try:
                pos_int = int(pos)
            except ValueError:
                continue

            ref = (r.get("other_allele") or "").upper().replace(" ", "")
            alt = (r.get("effect_allele") or "").upper().replace(" ", "")

            # Basic sanity: skip if missing alleles or REF == ALT
            if not ref or not alt or ref == alt:
                continue

            rsid = (r.get("hm_rsID") or r.get("rsID") or ".").strip() or "."
            qual = "."
            filt = "PASS"

            # Build INFO
            weight = (r.get("effect_weight") or "").strip()
            eaf = (r.get("allelefrequency_effect") or "").strip()
            hm_source = (r.get("hm_source") or "").replace(" ", "_")
            hm_match_chr = (r.get("hm_match_chr") or "").strip()
            hm_match_pos = (r.get("hm_match_pos") or "").strip()
            info_parts = [f"PGSID={pgsid}"]
            if weight:
                # ensure numeric formatting
                try:
                    info_parts.append(f"EFFECT_WEIGHT={float(weight)}")
                except ValueError:
                    pass
            if eaf:
                try:
                    info_parts.append(f"EAF={float(eaf)}")
                except ValueError:
                    pass
            if hm_source:
                info_parts.append(f"HM_SOURCE={hm_source}")
            if hm_match_chr or hm_match_pos:
                info_parts.append(f"HM_MATCH=chr:{hm_match_chr}|pos:{hm_match_pos}")
            info = ";".join(info_parts)

            # Write VCF line
            oh.write(f"{chrom}\t{pos_int}\t{rsid}\t{ref}\t{alt}\t{qual}\t{filt}\t{info}\n")

if __name__ == "__main__":
    main()
