#!/usr/bin/env python3
"""Convert decoded F Prime data-product JSON files into graph-friendly CSVs.

The default output is one *wide* CSV per container ID. Records that share a
sample timestamp are combined into one row, and each location gets its own
columns, for example:

    timestamp,OBC_current,OBC_power,OBC_voltage,JETSON_current,...

This makes the output easy to graph in Excel, LibreOffice, Python, MATLAB, etc.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable


LONG_BASE_COLUMNS = [
    "source_file",
    "container_id",
    "container_time_seconds",
    "container_time_microseconds",
    "record_id",
    "record_name",
    "record_type",
]

WIDE_BASE_COLUMNS = [
    "source_file",
    "container_id",
    "container_time_seconds",
    "container_time_microseconds",
    "timestamp",
]

WRAPPER_METADATA_KEYS = {
    "format",
    "description",
    "type",
    "name",
    "size",
}

# These fields identify a record/series rather than being a measured value.
SERIES_FIELD_CANDIDATES = (
    "location",
    "sensorName",
    "sourceName",
    "zoneName",
    "deviceName",
)


def unwrap_decoded_value(node: Any) -> Any:
    """Remove fprime-dp metadata wrappers while preserving actual values."""
    if isinstance(node, dict):
        if "value" in node:
            return unwrap_decoded_value(node["value"])

        if "values" in node and isinstance(node["values"], list):
            return [unwrap_decoded_value(value) for value in node["values"]]

        return {
            key: unwrap_decoded_value(value)
            for key, value in node.items()
            if key not in WRAPPER_METADATA_KEYS
        }

    if isinstance(node, list):
        return [unwrap_decoded_value(value) for value in node]

    return node


def flatten_value(prefix: str, value: Any, output: dict[str, Any]) -> None:
    """Flatten nested decoded values into CSV-compatible columns."""
    if isinstance(value, dict):
        for key, child in value.items():
            child_prefix = f"{prefix}.{key}" if prefix else key
            flatten_value(child_prefix, child, output)
        return

    if isinstance(value, list):
        output[prefix] = json.dumps(value, separators=(",", ":"))
        return

    output[prefix] = value


def get_wrapped_value(mapping: dict[str, Any], key: str, default: Any = "") -> Any:
    item = mapping.get(key, default)
    if isinstance(item, dict) and "value" in item:
        return item["value"]
    return item


def rows_from_file(path: Path, input_root: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8") as stream:
        document = json.load(stream)

    header = document.get("Header", {})
    header_time = header.get("Time", {})

    container_id = get_wrapped_value(header, "Id")
    time_seconds = header_time.get("seconds", "") if isinstance(header_time, dict) else ""
    time_microseconds = (
        header_time.get("microseconds", "") if isinstance(header_time, dict) else ""
    )

    try:
        source_file = str(path.relative_to(input_root))
    except ValueError:
        source_file = path.name

    rows: list[dict[str, Any]] = []

    for item in document.get("Records", []):
        record = item.get("Record", {})
        data = item.get("Data", {})

        full_record_name = record.get("record_name", "")
        short_record_name = (
            full_record_name.rsplit(".", 1)[-1]
            if isinstance(full_record_name, str)
            else full_record_name
        )

        row: dict[str, Any] = {
            "source_file": source_file,
            "container_id": container_id,
            "container_time_seconds": time_seconds,
            "container_time_microseconds": time_microseconds,
            "record_id": record.get("record_id", ""),
            "record_name": short_record_name,
            "record_type": record.get("record_type_name", ""),
        }

        if isinstance(data, dict):
            for field_name, wrapped_value in data.items():
                value = unwrap_decoded_value(wrapped_value)
                flatten_value(field_name, value, row)

        rows.append(row)

    return rows


def sortable_number(value: Any) -> tuple[int, float | str]:
    try:
        return (0, float(value))
    except (TypeError, ValueError):
        return (1, str(value))


def deduplicate_rows(rows: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    unique_rows: list[dict[str, Any]] = []
    seen: set[str] = set()

    for row in rows:
        comparable = {key: value for key, value in row.items() if key != "source_file"}
        fingerprint = json.dumps(comparable, sort_keys=True, default=str)
        if fingerprint in seen:
            continue
        seen.add(fingerprint)
        unique_rows.append(row)

    return unique_rows


def safe_component(value: Any) -> str:
    """Convert a value into a safe CSV column or filename component."""
    text = str(value).strip()
    text = re.sub(r"[^A-Za-z0-9_.-]+", "_", text)
    return text.strip("_") or "unknown"


def get_series_name(row: dict[str, Any]) -> str:
    """Choose the label used to separate readings into columns."""
    for field in SERIES_FIELD_CANDIDATES:
        value = row.get(field)
        if value not in (None, ""):
            return safe_component(value)

    record_name = row.get("record_name")
    if record_name not in (None, ""):
        # Make record names slightly shorter and nicer as column prefixes.
        return safe_component(re.sub(r"Record$", "", str(record_name)))

    return f"record_{safe_component(row.get('record_id', 'unknown'))}"


def round_value(value: Any, digits: int | None) -> Any:
    """Round decoded floating-point noise while preserving integers/strings."""
    if digits is not None and isinstance(value, float):
        return round(value, digits)
    return value


def make_wide_rows(
    long_rows: list[dict[str, Any]],
    round_digits: int | None,
) -> list[dict[str, Any]]:
    """Pivot long records so each location/record has dedicated columns."""
    grouped: dict[tuple[Any, ...], dict[str, Any]] = {}

    # When no record timestamp exists, use a per-file occurrence counter so
    # unrelated records do not all collapse into a single row.
    missing_timestamp_counter: dict[tuple[Any, ...], int] = defaultdict(int)

    for row in long_rows:
        timestamp = row.get("timestamp", "")

        base_key = (
            row.get("source_file", ""),
            row.get("container_id", ""),
            row.get("container_time_seconds", ""),
            row.get("container_time_microseconds", ""),
        )

        if timestamp in (None, ""):
            missing_timestamp_counter[base_key] += 1
            sample_token: Any = f"sample_{missing_timestamp_counter[base_key]}"
        else:
            sample_token = timestamp

        key = base_key + (sample_token,)

        if key not in grouped:
            grouped[key] = {
                "source_file": row.get("source_file", ""),
                "container_id": row.get("container_id", ""),
                "container_time_seconds": row.get("container_time_seconds", ""),
                "container_time_microseconds": row.get("container_time_microseconds", ""),
                "timestamp": timestamp if timestamp not in (None, "") else sample_token,
            }

        output_row = grouped[key]
        series = get_series_name(row)

        for field, value in row.items():
            if field in LONG_BASE_COLUMNS or field == "timestamp":
                continue
            if field in SERIES_FIELD_CANDIDATES:
                continue

            column = f"{series}_{safe_component(field)}"
            value = round_value(value, round_digits)

            # Normally each series/field appears once per timestamp. If it does
            # repeat, retain it with a numbered suffix instead of overwriting it.
            if column in output_row and output_row[column] != value:
                suffix = 2
                candidate = f"{column}_{suffix}"
                while candidate in output_row:
                    suffix += 1
                    candidate = f"{column}_{suffix}"
                column = candidate

            output_row[column] = value

    wide_rows = list(grouped.values())
    wide_rows.sort(
        key=lambda row: (
            sortable_number(row.get("container_time_seconds")),
            sortable_number(row.get("container_time_microseconds")),
            sortable_number(row.get("timestamp")),
            str(row.get("source_file", "")),
        )
    )
    return wide_rows


def write_csv(
    rows: list[dict[str, Any]],
    output_path: Path,
    base_columns: list[str],
) -> None:
    dynamic_columns = sorted(
        {
            key
            for row in rows
            for key in row
            if key not in base_columns
        }
    )
    fieldnames = base_columns + dynamic_columns

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def sort_long_rows(rows: list[dict[str, Any]]) -> None:
    rows.sort(
        key=lambda row: (
            sortable_number(row.get("container_time_seconds")),
            sortable_number(row.get("container_time_microseconds")),
            sortable_number(row.get("timestamp")),
            sortable_number(row.get("record_id")),
            str(row.get("source_file", "")),
        )
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Recursively read fprime-dp decoded JSON files and write one "
            "graph-friendly CSV for each Header.Id.value container ID."
        )
    )
    parser.add_argument(
        "input_dir",
        type=Path,
        help="Directory containing decoded JSON files, including container-ID folders.",
    )
    parser.add_argument(
        "--output-dir",
        "-o",
        type=Path,
        default=None,
        help="CSV directory. Default: <input_dir>/csv",
    )
    parser.add_argument(
        "--layout",
        choices=("wide", "long", "both"),
        default="wide",
        help=(
            "wide: one row per timestamp with separate location columns; "
            "long: original one-record-per-row layout; both: create both. "
            "Default: wide"
        ),
    )
    parser.add_argument(
        "--deduplicate",
        action="store_true",
        help="Remove exact duplicate records within each container ID.",
    )
    parser.add_argument(
        "--round-digits",
        type=int,
        default=6,
        help=(
            "Decimal places used for floating-point readings. "
            "Use a negative value to disable rounding. Default: 6"
        ),
    )
    args = parser.parse_args()

    input_dir = args.input_dir.resolve()
    output_dir = (
        args.output_dir.resolve()
        if args.output_dir is not None
        else input_dir / "csv"
    )
    round_digits = None if args.round_digits < 0 else args.round_digits

    if not input_dir.is_dir():
        print(f"ERROR: Input directory does not exist: {input_dir}", file=sys.stderr)
        return 1

    # Avoid accidentally reading generated JSON from unrelated locations. The
    # output directory contains CSVs, but excluding it makes the intent clear.
    json_files = sorted(
        path
        for path in input_dir.rglob("*.json")
        if path.is_file() and output_dir not in path.parents
    )

    if not json_files:
        print(f"ERROR: No JSON files found under {input_dir}", file=sys.stderr)
        return 1

    rows_by_container: dict[str, list[dict[str, Any]]] = defaultdict(list)
    failed_files = 0

    for path in json_files:
        try:
            file_rows = rows_from_file(path, input_dir)
            if not file_rows:
                print(f"WARNING: No Records entries in {path}", file=sys.stderr)
                continue

            for row in file_rows:
                container_key = str(row.get("container_id", "unknown"))
                rows_by_container[container_key].append(row)

            container_ids = sorted(
                {str(row.get("container_id", "unknown")) for row in file_rows}
            )
            print(
                f"Read {len(file_rows):5d} records from {path.relative_to(input_dir)} "
                f"(container {', '.join(container_ids)})"
            )
        except (OSError, json.JSONDecodeError, TypeError, KeyError) as error:
            failed_files += 1
            print(f"WARNING: Skipping {path}: {error}", file=sys.stderr)

    if not rows_by_container:
        print("ERROR: JSON files were found, but no Records entries were decoded.", file=sys.stderr)
        return 1

    output_dir.mkdir(parents=True, exist_ok=True)
    total_records = 0

    for container_id in sorted(rows_by_container, key=sortable_number):
        long_rows = rows_by_container[container_id]

        if args.deduplicate:
            before = len(long_rows)
            long_rows = deduplicate_rows(long_rows)
            removed = before - len(long_rows)
            if removed:
                print(f"Container {container_id}: removed {removed} duplicate records")

        sort_long_rows(long_rows)
        safe_id = safe_component(container_id)

        if args.layout in ("wide", "both"):
            wide_rows = make_wide_rows(long_rows, round_digits)
            wide_name = f"{safe_id}.csv" if args.layout == "wide" else f"{safe_id}_wide.csv"
            wide_path = output_dir / wide_name
            write_csv(wide_rows, wide_path, WIDE_BASE_COLUMNS)
            print(
                f"Wrote {len(wide_rows):5d} graph-ready samples to {wide_path}"
            )

        if args.layout in ("long", "both"):
            rounded_long_rows = [
                {key: round_value(value, round_digits) for key, value in row.items()}
                for row in long_rows
            ]
            long_name = f"{safe_id}.csv" if args.layout == "long" else f"{safe_id}_long.csv"
            long_path = output_dir / long_name
            write_csv(rounded_long_rows, long_path, LONG_BASE_COLUMNS)
            print(f"Wrote {len(long_rows):5d} long-format records to {long_path}")

        total_records += len(long_rows)

    print(
        f"\nProcessed {total_records} records across "
        f"{len(rows_by_container)} container CSV file(s)."
    )

    if failed_files:
        print(f"Completed with {failed_files} skipped file(s).", file=sys.stderr)
        return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())