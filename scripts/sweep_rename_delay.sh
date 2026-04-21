#!/bin/zsh

set -euo pipefail

installed_workflow="${HOME}/Library/Services/New Text File Here.workflow"
poll_points=(0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4)
outer_delays=(0.2 0.3 0.4 0.5 0.6 0.8)
inner_delays=(0.05 0.1 0.15 0.2)
runs_per_candidate="${FINDER_FORGE_SWEEP_RUNS:-3}"

parse_csv_into_array() {
  local csv="${1}"
  local array_name="${2}"
  local item=""

  eval "${array_name}=()"
  for item in ${(s:,:)csv}; do
    [[ -n "${item}" ]] || continue
    eval "${array_name}+=(\"\${item}\")"
  done
}

usage() {
  cat <<'EOF'
Usage: ./scripts/sweep_rename_delay.sh [--outer 0.2,0.3,...] [--inner 0.05,0.1,...] [--runs N]

Environment:
  FINDER_FORGE_SWEEP_RUNS   default runs per candidate (default: 3)
EOF
}

while (( $# > 0 )); do
  case "${1}" in
    --outer)
      parse_csv_into_array "${2:-}" outer_delays
      shift 2
      ;;
    --inner)
      parse_csv_into_array "${2:-}" inner_delays
      shift 2
      ;;
    --runs)
      runs_per_candidate="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: ${1}" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "${installed_workflow}" ]]; then
  echo "Missing installed workflow: ${installed_workflow}" >&2
  echo "Run ./install.sh first." >&2
  exit 1
fi

tmp_base="${TMPDIR:-/tmp}"
tmp_base="${tmp_base%/}"
case_root="$(mktemp -d "${tmp_base}/finder-forge-sweep.XXXXXX")"
trap 'rm -rf "${case_root}"' EXIT

poll_finder_focus() {
  /usr/bin/osascript <<'APPLESCRIPT'
tell application "System Events"
  tell process "Finder"
    try
      return role description of value of attribute "AXFocusedUIElement"
    on error errMsg
      return "ERROR: " & errMsg
    end try
  end tell
end tell
APPLESCRIPT
}

patch_workflow_for_candidate() {
  local workflow_dir="${1}"
  local outer_delay="${2}"
  local inner_delay="${3}"
  local helper_path="${workflow_dir:h}/candidate_helper.sh"

  cat > "${helper_path}" <<EOF
#!/bin/zsh
set -euo pipefail
target_dir="\$1"
target_file="\${target_dir}/untitled.txt"
/usr/bin/printf '' > "\${target_file}"
/usr/bin/osascript - "\${target_file}" <<'APPLESCRIPT' >/dev/null
on run argv
  set targetFile to POSIX file (item 1 of argv) as alias
  tell application "Finder"
    activate
    reveal targetFile
    select targetFile
  end tell
end run
APPLESCRIPT
(
  /bin/sleep ${outer_delay}
  /usr/bin/osascript - "\${target_file}" <<'APPLESCRIPT' >/dev/null
on run argv
  set targetFile to POSIX file (item 1 of argv) as alias
  tell application "Finder"
    activate
    reveal targetFile
    select targetFile
  end tell
  delay ${inner_delay}
  try
    tell application "System Events"
      if not UI elements enabled then
        return
      end if
      tell process "Finder"
        set frontmost to true
        key code 36
      end tell
    end tell
  end try
end run
APPLESCRIPT
) >/dev/null 2>&1 &
EOF

  chmod 755 "${helper_path}"

  /usr/bin/perl -0pi -e 's#<string>"[^"]*/helpers/create_text_file\.sh" "\$@"</string>#<string>"'"${helper_path}"'" "\$@"</string>#' "${workflow_dir}/Contents/Resources/document.wflow"
}

run_candidate_once() {
  local workflow_dir="${1}"
  local target_dir="${2}"
  local first_text_field="never"
  local final_role=""
  local stable_after_success="false"
  local role=""
  local seen_text_field="false"
  local t=""
  local prev=0
  local delta=""

  automator -i "${target_dir}" "${workflow_dir}" >/dev/null 2>/dev/null

  for t in "${poll_points[@]}"; do
    delta="$(awk "BEGIN {printf \"%.2f\", ${t} - ${prev}}")"
    sleep "${delta}"
    prev="${t}"
    role="$(poll_finder_focus)"

    if [[ "${role}" == "text field" ]]; then
      if [[ "${seen_text_field}" == "false" ]]; then
        first_text_field="${t}"
        seen_text_field="true"
        stable_after_success="true"
      fi
    elif [[ "${seen_text_field}" == "true" ]]; then
      stable_after_success="false"
    fi

    final_role="${role}"
  done

  printf '%s|%s|%s\n' "${first_text_field}" "${final_role}" "${stable_after_success}"
}

printf 'Delay sweep using installed workflow: %s\n' "${installed_workflow}"
printf 'Candidates: outer=%s inner=%s runs=%s\n' "${(j:, :)outer_delays}" "${(j:, :)inner_delays}" "${runs_per_candidate}"
echo

best_candidate=""
best_total="999"
best_first_success="999"

for outer_delay in "${outer_delays[@]}"; do
  for inner_delay in "${inner_delays[@]}"; do
    candidate_root="${case_root}/outer-${outer_delay}_inner-${inner_delay}"
    workflow_copy="${candidate_root}/New Text File Here.workflow"
    mkdir -p "${candidate_root}"
    cp -R "${installed_workflow}" "${workflow_copy}"
    patch_workflow_for_candidate "${workflow_copy}" "${outer_delay}" "${inner_delay}"

    successes=0
    first_success_samples=()
    final_text_field_runs=0
    stable_runs=0

    for run_index in $(seq 1 "${runs_per_candidate}"); do
      target_dir="${candidate_root}/run-${run_index}"
      mkdir -p "${target_dir}"
      result="$(run_candidate_once "${workflow_copy}" "${target_dir}")"
      first_text_field="${result%%|*}"
      remainder="${result#*|}"
      final_role="${remainder%%|*}"
      stable_after_success="${result##*|}"

      if [[ "${first_text_field}" != "never" ]]; then
        successes=$((successes + 1))
        first_success_samples+=("${first_text_field}")
      fi

      if [[ "${final_role}" == "text field" ]]; then
        final_text_field_runs=$((final_text_field_runs + 1))
      fi

      if [[ "${stable_after_success}" == "true" ]]; then
        stable_runs=$((stable_runs + 1))
      fi
    done

    average_first_success="n/a"
    if (( ${#first_success_samples[@]} > 0 )); then
      average_first_success="$(
        printf '%s\n' "${first_success_samples[@]}" | awk '{sum+=$1} END {printf "%.2f", sum/NR}'
      )"
    fi

    printf 'outer=%-4s inner=%-4s success=%d/%d final_text_field=%d/%d stable=%d/%d first_success_avg=%s\n' \
      "${outer_delay}" "${inner_delay}" \
      "${successes}" "${runs_per_candidate}" \
      "${final_text_field_runs}" "${runs_per_candidate}" \
      "${stable_runs}" "${runs_per_candidate}" \
      "${average_first_success}"

    if (( successes == runs_per_candidate && final_text_field_runs == runs_per_candidate && stable_runs == runs_per_candidate )); then
      total_delay="$(awk "BEGIN {printf \"%.2f\", ${outer_delay} + ${inner_delay}}")"

      if awk "BEGIN {exit !(${total_delay} < ${best_total})}"; then
        best_total="${total_delay}"
        best_first_success="${average_first_success}"
        best_candidate="outer=${outer_delay} inner=${inner_delay}"
      elif [[ "${total_delay}" == "${best_total}" ]] && [[ "${average_first_success}" != "n/a" ]] && awk "BEGIN {exit !(${average_first_success} < ${best_first_success})}"; then
        best_first_success="${average_first_success}"
        best_candidate="outer=${outer_delay} inner=${inner_delay}"
      fi
    fi
  done
done

echo
if [[ -n "${best_candidate}" ]]; then
  printf 'Recommended candidate: %s total_delay=%ss first_success_avg=%ss\n' "${best_candidate}" "${best_total}" "${best_first_success}"
else
  echo "Recommended candidate: none met the all-runs success/stability rule"
fi
