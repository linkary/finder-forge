#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
repo_root="${script_dir:h}"
tmp_base="${TMPDIR:-/tmp}"
tmp_base="${tmp_base%/}"
tmp_root="$(mktemp -d "${tmp_base}/finder-forge-create.XXXXXX")"
trap 'rm -rf "${tmp_root}"' EXIT

mkdir -p "${tmp_root}/subdir"

echo "Test: creates untitled.txt in target folder"
/bin/zsh "${repo_root}/helpers/create_text_file.sh" "${tmp_root}" >/dev/null
[[ -f "${tmp_root}/untitled.txt" ]]

echo "Test: increments file names"
/bin/zsh "${repo_root}/helpers/create_text_file.sh" "${tmp_root}" >/dev/null
[[ -f "${tmp_root}/untitled 2.txt" ]]

echo "Test: creates inside selected subfolder"
/bin/zsh "${repo_root}/helpers/create_text_file.sh" "${tmp_root}/subdir" >/dev/null
[[ -f "${tmp_root}/subdir/untitled.txt" ]]

echo "PASS test_create_text_file.sh"
