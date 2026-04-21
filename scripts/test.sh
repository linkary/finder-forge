#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"

swift "${script_dir}/verify_localizations.swift"
/bin/zsh "${script_dir}/test_install_upgrade.sh"
/bin/zsh "${script_dir}/test_create_text_file.sh"

echo "All Finder Forge automated tests passed."
