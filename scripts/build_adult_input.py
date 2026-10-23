"""Build the bundled domain-level comparison from a pinned adult checkout."""

import argparse
import csv
import gzip
import hashlib
import io
from pathlib import Path

SOURCE_HASHES = {
    "piedomains_classification.csv.gz": (
        "f847e21d19cd20ada82449e8438babf1879fce4badc47ca57465804a31d25ea6"
    ),
    "vt_domain_categories.csv": (
        "0bde99f39e87a490b5b0d56fa28d51310b8bb3cc32e9a7dd897c549eef71ec75"
    ),
}
REFERENCES = {
    "forcepoint_sex": ("forcepoint_threatseeker", "sex"),
    "bitdefender_porn": ("bitdefender", "porn"),
    "alphamountain_porn": ("alphamountain_ai", "Pornography"),
}
OUTPUT_COLUMNS = ["entity", "visits", "piedomains_porn", *REFERENCES]


def verify_source(path, expected):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            digest.update(chunk)
    if digest.hexdigest() != expected:
        raise ValueError(f"Source hash differs: {path}")


def read_categories(path):
    categories = {}
    with path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            domain = row["domain"]
            if not domain or domain in categories:
                raise ValueError("Missing or repeated domain in vendor categories")
            categories[domain] = row
    return categories


def build(source_repo, output):
    source_dir = source_repo / "data"
    for filename, expected in SOURCE_HASHES.items():
        verify_source(source_dir / filename, expected)
    categories = read_categories(source_dir / "vt_domain_categories.csv")
    records = []
    seen = set()
    matched = 0
    with gzip.open(
        source_dir / "piedomains_classification.csv.gz",
        "rt",
        newline="",
        encoding="utf-8",
    ) as stream:
        for row in csv.DictReader(stream):
            domain = row["private_domain"]
            if not domain or domain in seen:
                raise ValueError("Missing or repeated domain in Piedomains data")
            seen.add(domain)
            visits = int(row["tt_visits"])
            if visits <= 0 or not 0 <= float(row["label_prob"]) <= 1:
                raise ValueError("Invalid visits or classifier probability")
            prediction = int(
                row["pred_label"] == "porn" and float(row["label_prob"]) >= 0.033
            )
            matched += domain in categories
            vendor = categories.get(domain, {})
            reference = {
                name: "" if not vendor.get(column) else int(vendor[column] == positive)
                for name, (column, positive) in REFERENCES.items()
            }
            records.append((domain, visits, prediction, reference))
    if (
        len(records) != 64074
        or matched != 64064
        or sum(row[1] for row in records) != 6236834
    ):
        raise ValueError("Unexpected source frame size, join coverage, or visits")

    buffer = io.StringIO(newline="")
    writer = csv.DictWriter(buffer, fieldnames=OUTPUT_COLUMNS, lineterminator="\n")
    writer.writeheader()
    for domain, visits, prediction, reference in sorted(records):
        writer.writerow(
            {
                "entity": hashlib.sha256(domain.encode("utf-8")).hexdigest(),
                "visits": visits,
                "piedomains_porn": prediction,
                **reference,
            }
        )
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("wb") as stream:
        with gzip.GzipFile(
            fileobj=stream, mode="wb", filename="", mtime=0, compresslevel=9
        ) as zipped:
            zipped.write(buffer.getvalue().encode("utf-8"))
    print(f"Wrote {len(records)} domains to {output}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "source_repo", type=Path, help="Checkout of soodoku/adult at the pinned commit"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "data" / "adult_domains.csv.gz",
    )
    args = parser.parse_args()
    build(args.source_repo, args.output)


if __name__ == "__main__":
    main()
