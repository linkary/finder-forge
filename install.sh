#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
install_root="${HOME}/Library/Application Support/FinderQuickActions"
helpers_dir="${install_root}/helpers"
services_dir="${HOME}/Library/Services"
workflows_source_dir="${script_dir}/workflows"

if [[ ! -d "${workflows_source_dir}" ]]; then
  echo "Missing workflows directory: ${workflows_source_dir}" >&2
  exit 1
fi

mkdir -p "${helpers_dir}" "${services_dir}"

cp "${script_dir}/helpers/"*.sh "${helpers_dir}/"
chmod 755 "${helpers_dir}/"*.sh

escaped_install_root="${install_root//\//\\/}"

for source_workflow in "${workflows_source_dir}"/*.workflow; do
  workflow_name="${source_workflow:t}"
  destination_workflow="${services_dir}/${workflow_name}"

  rm -rf "${destination_workflow}"
  mkdir -p "${destination_workflow}/Contents/Resources"

  cp "${source_workflow}/Contents/Info.plist" "${destination_workflow}/Contents/Info.plist"
  sed "s/__INSTALL_DIR__/${escaped_install_root}/g" \
    "${source_workflow}/Contents/Resources/document.wflow" \
    > "${destination_workflow}/Contents/Resources/document.wflow"
done

/System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true

cat <<EOF
Installed Finder Quick Actions to:
  ${services_dir}

Shared helpers were installed to:
  ${helpers_dir}

If the actions do not appear immediately, relaunch Finder or log out and back in.
EOF
