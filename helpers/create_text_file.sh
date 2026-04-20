#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
source "${script_dir}/finder_context.sh"

target_directory="$(resolve_creation_directory "$@")"

if [[ ! -d "${target_directory}" ]]; then
  show_alert "The target folder does not exist: ${target_directory}"
  exit 1
fi

target_file="$(next_available_text_file "${target_directory}")"
/usr/bin/printf '' > "${target_file}"
reveal_in_finder "${target_file}"
