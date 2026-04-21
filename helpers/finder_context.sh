#!/bin/zsh

set -euo pipefail

show_alert() {
  local message="${1}"
  local title="${2:-Finder Forge}"
  /usr/bin/osascript - "${title}" "${message}" <<'APPLESCRIPT' >/dev/null
on run argv
  display alert (item 1 of argv) message (item 2 of argv) as critical
end run
APPLESCRIPT
}

finder_current_directory() {
  /usr/bin/osascript <<'APPLESCRIPT'
tell application "Finder"
  if not (exists Finder window 1) then
    return POSIX path of (desktop as alias)
  end if

  try
    set currentTarget to (target of front Finder window) as alias
  on error
    set currentTarget to (desktop as alias)
  end try

  return POSIX path of currentTarget
end tell
APPLESCRIPT
}

resolve_creation_directory() {
  if (( $# == 1 )) && [[ -d "$1" ]]; then
    printf '%s\n' "$1"
    return
  fi

  if (( $# == 1 )) && [[ -e "$1" ]]; then
    /usr/bin/dirname "$1"
    return
  fi

  finder_current_directory
}

resolve_editor_targets() {
  if (( $# > 0 )); then
    printf '%s\n' "$@"
    return
  fi

  finder_current_directory
}

next_available_text_file() {
  local directory="${1}"
  local base_name="untitled"
  local extension=".txt"
  local candidate="${directory}/${base_name}${extension}"
  local index=2

  while [[ -e "${candidate}" ]]; do
    candidate="${directory}/${base_name} ${index}${extension}"
    (( index++ ))
  done

  printf '%s\n' "${candidate}"
}

reveal_in_finder() {
  local target_path="${1}"
  /usr/bin/osascript - "${target_path}" <<'APPLESCRIPT' >/dev/null
on run argv
  set targetFile to POSIX file (item 1 of argv) as alias
  tell application "Finder"
    activate
    reveal targetFile
    select targetFile
  end tell
end run
APPLESCRIPT
}

reveal_and_begin_rename_in_finder() {
  local target_path="${1}"
  /usr/bin/osascript - "${target_path}" <<'APPLESCRIPT' >/dev/null
on run argv
  set targetFile to POSIX file (item 1 of argv) as alias

  tell application "Finder"
    activate
    reveal targetFile
    select targetFile
  end tell

  try
    tell application "System Events"
      if not UI elements enabled then
        return
      end if

      tell process "Finder"
        set frontmost to true
      end tell

      repeat 8 times
        delay 0.15

        tell process "Finder"
          set frontmost to true
          key code 36
        end tell

        delay 0.1

        tell process "Finder"
          try
            set focusedElement to value of attribute "AXFocusedUIElement"
            if role description of focusedElement is "text field" then
              exit repeat
            end if
          end try
        end tell
      end repeat
    end tell
  on error
    -- Best effort only: file creation and selection should still succeed even if
    -- Finder inline rename cannot be entered from a Service invocation.
    return
  end try
end run
APPLESCRIPT
}
