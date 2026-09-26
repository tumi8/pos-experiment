#!/usr/bin/env python3
"""
Throughput evaluation script for pos/MoonGen benchmark result folders.

What it does
------------
1.  Walks a given result folder recursively and picks out the log files
    that match FILE_FILTER (see CONFIGURATION below) -- this is how you
    tell the script which files actually contain the measurement you
    want to evaluate (e.g. only the loadgen/sender side, only the
    reflector/receiver side, or everything).
2.  Parses every matching file for MoonGen-style "RX:"/"TX:" throughput
    lines and computes basic statistics (mean, std, min, max, median)
    with numpy.
3.  Finds the ".loop" file that belongs to the same run (matched via the
    "_runN" suffix in the filename) and prints out whatever variables it
    contains (e.g. {"pkt_size": 64}), so every throughput result is
    labeled with the parameter it was measured at.

Usage
-----
    python evaluate_throughput.py /path/to/result_folder
    python evaluate_throughput.py /path/to/result_folder --filter "*.stdout"

Adapting it to your own data
-----------------------------
Everything you are likely to want to change lives in the CONFIGURATION
section right below: which files to parse (FILE_FILTER), how a
throughput line looks (THROUGHPUT_LINE_RE) and how run numbers /
loop-files are matched (RUN_ID_RE). The parsing/statistics/reporting
functions further down should not normally need to change.
"""

import argparse
import json
import re
from pathlib import Path

import numpy as np

# ----------------------------------------------------------------------
# CONFIGURATION -- adapt this to your evaluation
# ----------------------------------------------------------------------

# Glob pattern (relative to the result folder, matched recursively) that
# selects which files are parsed for throughput numbers. This is the
# "filter" you need to set depending on what you want to evaluate.
#
# Examples for this kind of pos/MoonGen result folder:
#   "*loadgen_run*.stdout"    -> only the sender (loadgen) output files
#   "*reflector_run*.stdout"  -> only the receiver (reflector) output files
#   "*.stdout"                -> every stdout file (incl. bootstrap/reset)

# TODO adapt file filter
FILE_FILTER = "*loadgen_run*.stdout"

# Regex that extracts one RX or TX throughput sample from a MoonGen log
# line, e.g.:
#   "[Device: id=0] RX: 22.88 Mpps, 13913 Mbit/s (17574 Mbit/s with framing)"
#   "[Device: id=0] RX: 54.02 (StdDev 0.51) Mpps, 30392 (StdDev 288) Mbit/s ..."
THROUGHPUT_LINE_RE = re.compile(
    r"\[Device:\s*id=\d+\]\s*(RX|TX):\s*"
    r"([\d.]+)\s*(?:\(StdDev[^)]*\)\s*)?Mpps,\s*"
    r"([\d.]+)\s*(?:\(StdDev[^)]*\)\s*)?Mbit/s"
)

# MoonGen colors its console output; this strips the ANSI escape codes
# before the regex above is applied.
ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-9;]*m")

# MoonGen prints one final "total ... packets ..." line per direction that
# already is an aggregate of all interval lines. Keep this False to compute
# the numpy statistics only from the raw per-interval samples; set it to
# True to also feed that aggregate line into the statistics as one more
# data point.
INCLUDE_AGGREGATE_LINE = False

# How a run number is extracted from a filename, e.g. "..._run3.stdout"
# -> run 3. This is used to match a throughput file to its ".loop" file
# (which is expected to sit in the same directory).
RUN_ID_RE = re.compile(r"_run(\d+)")


# ----------------------------------------------------------------------
# Parsing
# ----------------------------------------------------------------------

def find_files(root: Path, pattern: str):
    """Recursively find all files below root matching the glob pattern."""
    return sorted(root.rglob(pattern))


def extract_run_id(path: Path):
    """Return the run number encoded in a filename, or None if there isn't one."""
    match = RUN_ID_RE.search(path.stem)
    return int(match.group(1)) if match else None


def parse_throughput_file(path: Path):
    """Read one log file and return raw RX/TX samples as numpy arrays."""
    samples = {"RX_Mpps": [], "RX_Mbit": [], "TX_Mpps": [], "TX_Mbit": []}

    text = path.read_text(errors="replace")
    for raw_line in text.splitlines():
        line = ANSI_ESCAPE_RE.sub("", raw_line)

        is_aggregate_line = "total" in line and "packets" in line
        if is_aggregate_line and not INCLUDE_AGGREGATE_LINE:
            continue

        match = THROUGHPUT_LINE_RE.search(line)
        if not match:
            continue

        direction, mpps, mbit = match.groups()
        samples[f"{direction}_Mpps"].append(float(mpps))
        samples[f"{direction}_Mbit"].append(float(mbit))

    return {key: np.array(values, dtype=float) for key, values in samples.items()}


def find_loop_file(path: Path, run_id):
    """Find the .loop file belonging to the same run, in the same directory."""
    if run_id is None:
        return None
    candidates = sorted(path.parent.glob(f"*_run{run_id}.loop"))
    return candidates[0] if candidates else None


def read_loop_variables(loop_path):
    """Read a .loop file (JSON) and return its variables as a dict."""
    if loop_path is None:
        return {}
    try:
        return json.loads(loop_path.read_text())
    except (json.JSONDecodeError, OSError):
        return {}


def compute_stats(values: np.ndarray):
    """Basic numpy statistics for one array of samples."""
    if values.size == 0:
        return None
    return {
        "count": int(values.size),
        "mean": float(np.mean(values)),
        "std": float(np.std(values)),
        "min": float(np.min(values)),
        "max": float(np.max(values)),
        "median": float(np.median(values)),
    }


# ----------------------------------------------------------------------
# Reporting
# ----------------------------------------------------------------------

def format_stats_line(label, stats, unit):
    if stats is None:
        return f"    {label:<10s} no data"
    return (
        f"    {label:<10s} "
        f"mean={stats['mean']:10.2f} {unit:<7s} "
        f"std={stats['std']:8.2f}  "
        f"min={stats['min']:10.2f}  "
        f"max={stats['max']:10.2f}  "
        f"median={stats['median']:10.2f}  "
        f"(n={stats['count']})"
    )


def print_report(root: Path, file_filter: str, results):
    print("=" * 100)
    print(f"Throughput evaluation for: {root}")
    print(f"File filter used:          {file_filter}")
    print("=" * 100)

    if not results:
        print("No matching files found - check the filter and the given folder.")
        return

    for entry in results:
        rel_path = entry["path"].relative_to(root)
        run_id = entry["run_id"]
        loop_vars = entry["loop_vars"]

        header = f"\n[{rel_path}]"
        if run_id is not None:
            header += f"  (run {run_id})"
        print(header)

        if loop_vars:
            var_str = ", ".join(f"{k}={v}" for k, v in loop_vars.items())
            print(f"  loop variables: {var_str}")
        elif run_id is not None:
            print("  loop variables: <no matching .loop file found>")

        stats = entry["stats"]
        print(format_stats_line("RX", stats["RX_Mpps"], "Mpps"))
        print(format_stats_line("RX", stats["RX_Mbit"], "Mbit/s"))
        print(format_stats_line("TX", stats["TX_Mpps"], "Mpps"))
        print(format_stats_line("TX", stats["TX_Mbit"], "Mbit/s"))


# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description="Evaluate throughput statistics from pos/MoonGen result folders."
    )
    parser.add_argument(
        "folder",
        type=Path,
        help="Path to the result folder to evaluate (searched recursively).",
    )
    parser.add_argument(
        "--filter",
        default=FILE_FILTER,
        help=f"Glob pattern selecting which files to parse (default: '{FILE_FILTER}').",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    root = args.folder.resolve()
    file_filter = args.filter

    if not root.is_dir():
        raise SystemExit(f"Error: '{root}' is not a directory.")

    files = find_files(root, file_filter)

    results = []
    for path in files:
        run_id = extract_run_id(path)
        loop_path = find_loop_file(path, run_id)
        loop_vars = read_loop_variables(loop_path)
        stats = {
            key: compute_stats(values)
            for key, values in parse_throughput_file(path).items()
        }
        results.append(
            {"path": path, "run_id": run_id, "loop_vars": loop_vars, "stats": stats}
        )

    # Sort by run number (files without one go last), then by path.
    results.sort(key=lambda e: (e["run_id"] is None, e["run_id"], str(e["path"])))

    print_report(root, file_filter, results)


if __name__ == "__main__":
    main()
