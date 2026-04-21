#!/bin/zsh

set -euo pipefail
: "${HOME:?HOME must be set}"

script_dir="${0:A:h}"
install_root="${HOME}/Library/Application Support/FinderForge"
helpers_dir="${install_root}/helpers"
install_state_file="${install_root}/install-state.txt"
services_dir="${HOME}/Library/Services"
workflows_source_dir="${script_dir}/workflows"
source "${script_dir}/helpers/editor_config.sh"

managed_asset_generation="2026-04-21-localization-rename-upgrade-safe"

managed_workflows=(
  "New Text File Here.workflow"
  "Open in Qoder.workflow"
  "Open in Cursor.workflow"
  "Open in Code.workflow"
)

# Finder Forge has not shipped renamed workflow bundles yet, but keep the
# cleanup contract explicit so future upgrades can remove prior names safely.
legacy_managed_workflows=(
)

managed_workflow_cleanup_names=(
  "${managed_workflows[@]}"
  "${legacy_managed_workflows[@]}"
)

typeset -A workflow_keys=(
  "Open in Qoder.workflow" qoder
  "Open in Cursor.workflow" cursor
  "Open in Code.workflow" code
)

if [[ ! -d "${workflows_source_dir}" ]]; then
  echo "Missing workflows directory: ${workflows_source_dir}" >&2
  exit 1
fi

remove_managed_workflows() {
  local workflow_name
  for workflow_name in "${managed_workflow_cleanup_names[@]}"; do
    rm -rf "${services_dir}/${workflow_name}"
  done
}

write_install_state() {
  local source_revision="archive"
  local source_origin="archive"

  if git -C "${script_dir}" rev-parse --short HEAD >/dev/null 2>&1; then
    source_revision="$(git -C "${script_dir}" rev-parse --short HEAD)"
  fi

  if git -C "${script_dir}" config --get remote.origin.url >/dev/null 2>&1; then
    source_origin="$(git -C "${script_dir}" config --get remote.origin.url)"
  fi

  cat > "${install_state_file}" <<EOF
project=Finder Forge
managed_asset_generation=${managed_asset_generation}
installed_at_utc=$(/bin/date -u +"%Y-%m-%dT%H:%M:%SZ")
source_revision=${source_revision}
source_origin=${source_origin}
helpers_dir=${helpers_dir}
services_dir=${services_dir}
installed_workflows=${(j:,:)installed_workflows}
skipped_workflows=${(j:,:)skipped_workflows}
EOF
}

refresh_services() {
  /System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
}

install_workflow() {
  local workflow_name="${1}"
  local source_workflow="${workflows_source_dir}/${workflow_name}"
  local destination_workflow="${services_dir}/${workflow_name}"

  cp -R "${source_workflow}" "${destination_workflow}"
  sed "s/__INSTALL_DIR__/${escaped_install_root}/g" \
    "${source_workflow}/Contents/Resources/document.wflow" \
    > "${destination_workflow}/Contents/Resources/document.wflow"
}

uninstall() {
  remove_managed_workflows
  rm -rf "${install_root}"
  refresh_services
  cat <<EOF
Removed Finder Forge Quick Actions from:
  ${services_dir}

Removed Finder Forge support files from:
  ${install_root}

If Finder still shows stale actions, relaunch Finder or log out and back in.
EOF
}

if (( $# > 1 )); then
  echo "Usage: ./install.sh [uninstall]" >&2
  exit 1
fi

if (( $# == 1 )); then
  case "${1}" in
    uninstall)
      uninstall
      exit 0
      ;;
    *)
      echo "Usage: ./install.sh [uninstall]" >&2
      exit 1
      ;;
  esac
fi

rm -rf "${helpers_dir}"
mkdir -p "${install_root}" "${helpers_dir}" "${services_dir}"

cp "${script_dir}/helpers/"*.sh "${helpers_dir}/"
chmod 755 "${helpers_dir}/"*.sh

escaped_install_root="${install_root//\//\\/}"
remove_managed_workflows

installed_workflows=()
skipped_workflows=()

install_workflow "New Text File Here.workflow"
installed_workflows+=("New Text File Here")

for workflow_name in "${(@k)workflow_keys}"; do
  app_key="${workflow_keys[${workflow_name}]}"
  app_path="${EDITOR_PATHS[${app_key}]}"
  app_name="${EDITOR_NAMES[${app_key}]}"

  if [[ -d "${app_path}" ]]; then
    install_workflow "${workflow_name}"
    installed_workflows+=("${workflow_name%.workflow}")
  else
    skipped_workflows+=("${workflow_name%.workflow} (${app_name} missing at ${app_path})")
  fi
done

write_install_state
refresh_services

cat <<EOF
Installed Finder Forge Quick Actions to:
  ${services_dir}

Shared helpers were installed to:
  ${helpers_dir}

Install state was written to:
  ${install_state_file}

Installed workflows:
$(printf '  - %s\n' "${installed_workflows[@]}")
EOF

if (( ${#skipped_workflows[@]} > 0 )); then
  cat <<EOF
Skipped workflows:
$(printf '  - %s\n' "${skipped_workflows[@]}")
EOF
fi

cat <<EOF
If the actions do not appear immediately, relaunch Finder or log out and back in.
EOF
