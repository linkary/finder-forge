#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
source "${script_dir}/finder_context.sh"

# Update these paths if any editor is moved or renamed.
typeset -A EDITOR_PATHS=(
  qoder "/Applications/Qoder.app"
  cursor "/Applications/Cursor.app"
  code "/Applications/Visual Studio Code.app"
)

typeset -A EDITOR_NAMES=(
  qoder "Qoder"
  cursor "Cursor"
  code "Visual Studio Code"
)

app_key=""

while (( $# > 0 )); do
  case "$1" in
    --app-key)
      app_key="${2:-}"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

if [[ -z "${app_key}" || -z "${EDITOR_PATHS[${app_key}]:-}" ]]; then
  show_alert "The workflow is misconfigured. Expected one of: qoder, cursor, code."
  exit 1
fi

app_path="${EDITOR_PATHS[${app_key}]}"
app_name="${EDITOR_NAMES[${app_key}]}"

if [[ ! -d "${app_path}" ]]; then
  show_alert "${app_name} is not available at ${app_path}. Update helpers/open_in_editor.sh or reinstall the editor."
  exit 1
fi

targets=("${(@f)$(resolve_editor_targets "$@")}")

if (( ${#targets[@]} == 0 )); then
  show_alert "Finder did not provide a folder or selection to open."
  exit 1
fi

/usr/bin/open -a "${app_path}" -- "${targets[@]}"
