#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
repo_root="${script_dir:h}"
tmp_base="${TMPDIR:-/tmp}"
tmp_base="${tmp_base%/}"
tmp_home="$(mktemp -d "${tmp_base}/finder-forge-home.XXXXXX")"
tmp_repo_root="$(mktemp -d "${tmp_base}/finder-forge-repo.XXXXXX")"
tmp_apps_root="$(mktemp -d "${tmp_base}/finder-forge-apps.XXXXXX")"
fake_qoder_app="${tmp_apps_root}/Qoder.app"
fake_cursor_app="${tmp_apps_root}/Cursor.app"
fake_code_app="${tmp_apps_root}/Visual Studio Code.app"
trap 'rm -rf "${tmp_home}" "${tmp_repo_root}" "${tmp_apps_root}"' EXIT

repo_copy="${tmp_repo_root}/repo"
mkdir -p "${repo_copy}"
/usr/bin/rsync -a --exclude .git "${repo_root}/" "${repo_copy}/"
mkdir -p "${fake_qoder_app}" "${fake_cursor_app}" "${fake_code_app}"

/usr/bin/perl -0pi -e "s#/Applications/Qoder\\.app#${fake_qoder_app}#g; s#/Applications/Cursor\\.app#${fake_cursor_app}#g; s#/Applications/Visual Studio Code\\.app#${fake_code_app}#g" "${repo_copy}/helpers/editor_config.sh"

echo "Test: install is repeatable"
HOME="${tmp_home}" /bin/zsh "${repo_copy}/install.sh" >/dev/null
HOME="${tmp_home}" /bin/zsh "${repo_copy}/install.sh" >/dev/null

state_file="${tmp_home}/Library/Application Support/FinderForge/install-state.txt"
helpers_dir="${tmp_home}/Library/Application Support/FinderForge/helpers"
cursor_workflow="${tmp_home}/Library/Services/Open in Cursor.workflow"

[[ -f "${state_file}" ]]
/usr/bin/grep -q 'managed_asset_generation=2026-04-21-localization-rename-upgrade-safe' "${state_file}"

echo "Test: stale helpers are removed on reinstall"
/usr/bin/touch "${helpers_dir}/stale-helper.sh"
[[ -f "${helpers_dir}/stale-helper.sh" ]]
HOME="${tmp_home}" /bin/zsh "${repo_copy}/install.sh" >/dev/null
[[ ! -e "${helpers_dir}/stale-helper.sh" ]]

echo "Test: missing editor removes old workflow on reinstall"
[[ -d "${cursor_workflow}" ]]
/bin/rm -rf "${fake_cursor_app}"
HOME="${tmp_home}" /bin/zsh "${repo_copy}/install.sh" >/dev/null
[[ ! -e "${cursor_workflow}" ]]
[[ -d "${tmp_home}/Library/Services/New Text File Here.workflow" ]]
[[ -d "${tmp_home}/Library/Services/Open in Code.workflow" ]]
[[ -d "${tmp_home}/Library/Services/Open in Qoder.workflow" ]]

echo "Test: uninstall removes managed files"
HOME="${tmp_home}" /bin/zsh "${repo_copy}/install.sh" uninstall >/dev/null
[[ ! -e "${tmp_home}/Library/Application Support/FinderForge" ]]
[[ ! -e "${tmp_home}/Library/Services/New Text File Here.workflow" ]]

echo "PASS test_install_upgrade.sh"
