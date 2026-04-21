#!/bin/zsh

set -euo pipefail
: "${HOME:?HOME must be set}"

project_name="Finder Forge"
install_root="${HOME}/Library/Application Support/FinderForge"
services_dir="${HOME}/Library/Services"
script_source="${(%):-%N}"
managed_workflows=(
  "New Text File Here.workflow"
  "Open in Qoder.workflow"
  "Open in Cursor.workflow"
  "Open in Code.workflow"
)

github_owner="${FINDER_FORGE_GITHUB_OWNER:-linkary}"
github_repo="${FINDER_FORGE_GITHUB_REPO:-finder-forge}"
github_ref="${FINDER_FORGE_GITHUB_REF:-main}"
archive_url="${FINDER_FORGE_ARCHIVE_URL:-https://github.com/${github_owner}/${github_repo}/archive/refs/heads/${github_ref}.zip}"

temp_root=""

cleanup() {
  if [[ -n "${temp_root}" && -d "${temp_root}" ]]; then
    rm -rf "${temp_root}"
  fi
}

trap cleanup EXIT

usage() {
  cat <<EOF
Usage: bootstrap-install.sh [install|uninstall]

If no argument is provided, ${project_name} prompts for:
  1. Install
  2. Uninstall

Optional environment overrides:
  FINDER_FORGE_ARCHIVE_URL
  FINDER_FORGE_GITHUB_OWNER
  FINDER_FORGE_GITHUB_REPO
  FINDER_FORGE_GITHUB_REF
EOF
}

refresh_services() {
  /System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
}

remove_managed_workflows() {
  local workflow_name

  for workflow_name in "${managed_workflows[@]}"; do
    rm -rf "${services_dir}/${workflow_name}"
  done
}

uninstall_finder_forge() {
  remove_managed_workflows
  rm -rf "${install_root}"
  refresh_services

  cat <<EOF
Removed ${project_name} Quick Actions from:
  ${services_dir}

Removed ${project_name} support files from:
  ${install_root}

If Finder still shows stale actions, relaunch Finder or log out and back in.
EOF
}

resolve_local_bundle_root() {
  local script_path=""
  local script_dir=""
  local candidate_path=""

  for candidate_path in "${script_source}" "${0}"; do
    if [[ "${candidate_path}" == /* && -f "${candidate_path}" ]]; then
      script_path="${candidate_path}"
      break
    elif [[ -f "${PWD}/${candidate_path}" ]]; then
      script_path="${PWD}/${candidate_path}"
      break
    fi
  done

  [[ -n "${script_path}" ]] || return 1

  script_dir="${script_path:A:h}"

  if [[ -f "${script_dir}/install.sh" && -d "${script_dir}/workflows" && -d "${script_dir}/helpers" ]]; then
    printf '%s\n' "${script_dir}"
    return 0
  fi

  return 1
}

download_bundle_root() {
  local archive_path=""
  local candidate=""
  local bundle_root=""

  temp_root="$(mktemp -d "${TMPDIR:-/tmp}/finder-forge.XXXXXX")"
  archive_path="${temp_root}/finder-forge.zip"

  echo "Downloading ${project_name} from:"
  echo "  ${archive_url}"

  curl -fsSL "${archive_url}" -o "${archive_path}"
  unzip -q "${archive_path}" -d "${temp_root}"

  for candidate in "${temp_root}"/*; do
    if [[ -d "${candidate}" && -f "${candidate}/install.sh" ]]; then
      bundle_root="${candidate}"
      break
    fi
  done

  if [[ -z "${bundle_root}" ]]; then
    echo "Unable to locate install.sh inside the downloaded archive." >&2
    exit 1
  fi

  printf '%s\n' "${bundle_root}"
}

run_bundle_installer() {
  local action="${1}"
  local bundle_root=""

  if bundle_root="$(resolve_local_bundle_root)"; then
    :
  else
    bundle_root="$(download_bundle_root)"
  fi

  if [[ "${action}" == "install" ]]; then
    zsh "${bundle_root}/install.sh"
  else
    zsh "${bundle_root}/install.sh" uninstall
  fi
}

prompt_for_action() {
  local choice=""

  cat <<EOF >/dev/tty
${project_name}
1. Install
2. Uninstall
EOF

  while true; do
    printf 'Choose an option [1-2]: ' >/dev/tty
    # When invoked via curl | zsh, stdin is the script body, so prompts must read from the terminal.
    read -r choice </dev/tty || exit 1

    case "${choice}" in
      1|install|Install)
        printf '%s\n' "install"
        return 0
        ;;
      2|uninstall|Uninstall)
        printf '%s\n' "uninstall"
        return 0
        ;;
      *)
        echo "Enter 1 for Install or 2 for Uninstall." >/dev/tty
        ;;
    esac
  done
}

main() {
  local action="${1:-}"

  case "${action}" in
    "")
      action="$(prompt_for_action)"
      ;;
    install|uninstall)
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac

  if [[ "${action}" == "install" ]]; then
    run_bundle_installer install
  else
    uninstall_finder_forge
  fi
}

main "${1:-}"
