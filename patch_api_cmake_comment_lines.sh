#!/usr/bin/env bash
set -euo pipefail

# Comments out specific line numbers in lib/fprime/cmake/API.cmake.
# Usage:
#   ./patch_api_cmake_comment_lines.sh

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_FILE="${REPO_ROOT}/lib/fprime/cmake/API.cmake"

if [[ ! -f "${TARGET_FILE}" ]]; then
  echo "error: file not found: ${TARGET_FILE}" >&2
  exit 1
fi

# Ensure the file is long enough for the requested edits.
LINE_COUNT="$(wc -l < "${TARGET_FILE}" | tr -d ' ')"
if (( LINE_COUNT < 562 )); then
  echo "error: ${TARGET_FILE} has ${LINE_COUNT} lines; expected at least 562" >&2
  exit 1
fi

# Edit in-place.
# Only insert a comment marker if the line isn't already commented (after optional indentation).
sed -i \
  -e '545{/^[[:space:]]*#/! s/^[[:space:]]*/&#/}' \
  -e '562{/^[[:space:]]*#/! s/^[[:space:]]*/&#/}' \
  "${TARGET_FILE}"

echo "Patched: ${TARGET_FILE}"
