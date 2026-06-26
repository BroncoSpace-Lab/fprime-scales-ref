#!/usr/bin/python3
import sys
import json
import argparse
from pathlib import Path
from typing import Any, Dict, List, Optional


JsonDict = Dict[str, Any]


REQUIRED_SECTIONS = [
    "commands",
    "events",
    "telemetryChannels",
]


def load_json_dictionary(dict_file: Path) -> JsonDict:
    try:
        with open(dict_file, "r") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"[ERROR] Failed to parse JSON file {dict_file}: {e}")
        sys.exit(-1)

    if not isinstance(data, dict):
        print(f"[ERROR] Dictionary file {dict_file} does not contain a JSON object")
        sys.exit(-1)

    for section in REQUIRED_SECTIONS:
        if section not in data:
            print(f"[ERROR] {dict_file} has no '{section}' section")
            sys.exit(-1)

        if not isinstance(data[section], list):
            print(f"[ERROR] Section '{section}' in {dict_file} is not a list")
            sys.exit(-1)

    return data


def get_entry_key(entry: JsonDict, key: str) -> Optional[Any]:
    if not isinstance(entry, dict):
        return None

    return entry.get(key)


def entries_equal(a: JsonDict, b: JsonDict) -> bool:
    return a == b


def find_existing_entry(section: List[JsonDict], key: str, value: Any) -> Optional[JsonDict]:
    for entry in section:
        if get_entry_key(entry, key) == value:
            return entry

    return None


def merge_list_section(
    base_dict: JsonDict,
    filtered_dict: JsonDict,
    section_name: str,
    merge_key: str,
    allow_duplicates: bool = True,
):
    new_section = filtered_dict.get(section_name)

    if new_section is None:
        return

    if not isinstance(new_section, list):
        print(f"[ERROR] Section '{section_name}' in secondary dictionary is not a list")
        sys.exit(-1)

    if section_name not in base_dict:
        base_dict[section_name] = []

    base_section = base_dict[section_name]

    if not isinstance(base_section, list):
        print(f"[ERROR] Section '{section_name}' in base dictionary is not a list")
        sys.exit(-1)

    for entry in new_section:
        value = get_entry_key(entry, merge_key)

        if value is None:
            print(
                f"[WARNING] Skipping entry in section '{section_name}' "
                f"because it has no key '{merge_key}'"
            )
            continue

        existing = find_existing_entry(base_section, merge_key, value)

        if existing is not None:
            if not allow_duplicates and not entries_equal(existing, entry):
                print(
                    "[ERROR] Conflicting entries in base and secondary dictionary "
                    f"for {merge_key}={value} in section '{section_name}'"
                )
                sys.exit(-1)

            # Same key already exists. Skip it.
            continue

        base_section.append(entry)


def merge_metadata(base_dict: JsonDict, filtered_dict: JsonDict):
    """
    Keep the base metadata as the primary metadata, but record what was merged.

    This avoids changing fields like deploymentName, frameworkVersion, and
    dictionarySpecVersion in ways that might confuse F Prime tools.
    """
    base_metadata = base_dict.setdefault("metadata", {})

    if not isinstance(base_metadata, dict):
        print("[ERROR] Base metadata is not a JSON object")
        sys.exit(-1)

    secondary_metadata = filtered_dict.get("metadata", {})

    if isinstance(secondary_metadata, dict):
        base_metadata["mergedDictionary"] = {
            "deploymentName": secondary_metadata.get("deploymentName"),
            "projectVersion": secondary_metadata.get("projectVersion"),
            "frameworkVersion": secondary_metadata.get("frameworkVersion"),
            "dictionarySpecVersion": secondary_metadata.get("dictionarySpecVersion"),
        }


def merge_dicts(base_dict: JsonDict, filtered_dict: JsonDict) -> JsonDict:
    merge_metadata(base_dict, filtered_dict)

    # Type-level definitions. These can repeat across deployments, so duplicate
    # qualified names are skipped unless they are new.
    merge_list_section(
        base_dict,
        filtered_dict,
        "typeDefinitions",
        "qualifiedName",
        allow_duplicates=True,
    )

    merge_list_section(
        base_dict,
        filtered_dict,
        "constants",
        "qualifiedName",
        allow_duplicates=True,
    )

    # Runtime IDs/opcodes should not conflict across the combined dictionary.
    merge_list_section(
        base_dict,
        filtered_dict,
        "commands",
        "opcode",
        allow_duplicates=False,
    )

    merge_list_section(
        base_dict,
        filtered_dict,
        "events",
        "id",
        allow_duplicates=False,
    )

    merge_list_section(
        base_dict,
        filtered_dict,
        "telemetryChannels",
        "id",
        allow_duplicates=False,
    )

    merge_list_section(
        base_dict,
        filtered_dict,
        "parameters",
        "id",
        allow_duplicates=False,
    )

    # These may be empty depending on the deployment, but keep support for them.
    merge_list_section(
        base_dict,
        filtered_dict,
        "records",
        "name",
        allow_duplicates=False,
    )

    merge_list_section(
        base_dict,
        filtered_dict,
        "containers",
        "id",
        allow_duplicates=False,
    )

    merge_list_section(
        base_dict,
        filtered_dict,
        "telemetryPacketSets",
        "name",
        allow_duplicates=False,
    )

    return base_dict


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Combine multiple F Prime JSON deployment dictionaries together."
    )

    parser.add_argument(
        "base_dictionary",
        help="JSON dictionary to use as the base of the combined dictionary.",
    )

    parser.add_argument(
        "dictionary",
        help="Secondary JSON dictionary to combine into the base.",
    )

    parser.add_argument(
        "result",
        help="File to save the resulting combined JSON dictionary into.",
    )

    return parser.parse_args()


def main() -> int:
    args = parse_args()

    base_dict_file = Path(args.base_dictionary)
    if not base_dict_file.exists():
        print(f"[ERROR] Dictionary file {base_dict_file} does not exist")
        return -1

    dict_file = Path(args.dictionary)
    if not dict_file.exists():
        print(f"[ERROR] Dictionary file {dict_file} does not exist")
        return -1

    base_dict = load_json_dictionary(base_dict_file)
    filtered_dict = load_json_dictionary(dict_file)

    combined_dict = merge_dicts(base_dict, filtered_dict)

    result_file = Path(args.result)
    with open(result_file, "w") as f:
        json.dump(combined_dict, f, indent=2)
        f.write("\n")

    print(f"[INFO] Wrote merged dictionary to {result_file}")

    return 0


if __name__ == "__main__":
    sys.exit(main())