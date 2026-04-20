# Finder Forge

Finder Forge installs four Finder Quick Actions / Services on macOS:

- `New Text File Here`
- `Open in Qoder`
- `Open in Cursor`
- `Open in Code`

They are implemented as Automator `.workflow` bundles and shared shell helpers. The installer copies the workflows to `~/Library/Services` and the helpers to `~/Library/Application Support/FinderForge/helpers`.

## Behavior

- `New Text File Here` creates `untitled.txt` in the current Finder folder.
- If `untitled.txt` already exists, it creates `untitled 2.txt`, `untitled 3.txt`, and so on.
- If exactly one folder is selected, the new file is created inside that folder.
- If exactly one file is selected, the new file is created alongside that file.
- If multiple items are selected, the new file is created in the current Finder folder.
- Editor actions open the selected file or folder in the requested editor.
- If nothing is selected, editor actions open the current Finder folder or the Desktop.

## Install

Run:

```sh
./install.sh
```

The installer:

- copies the helpers into `~/Library/Application Support/FinderForge/helpers`
- copies each workflow into `~/Library/Services`
- rewrites the workflow command paths to point at the installed helpers
- asks macOS to rescan Services

## Configuration

Editor app paths live near the top of [helpers/open_in_editor.sh](/Users/linkary/Codes/Labs/Finder-Forge/helpers/open_in_editor.sh).

Current defaults:

- `Qoder`: `/Applications/Qoder.app`
- `Cursor`: `/Applications/Cursor.app`
- `Visual Studio Code`: `/Applications/Visual Studio Code.app`

If any editor moves, update those paths and rerun `./install.sh`.

## Layout

- [helpers/finder_context.sh](/Users/linkary/Codes/Labs/Finder-Forge/helpers/finder_context.sh): shared Finder context resolution and Finder UI helpers
- [helpers/create_text_file.sh](/Users/linkary/Codes/Labs/Finder-Forge/helpers/create_text_file.sh): file creation action
- [helpers/open_in_editor.sh](/Users/linkary/Codes/Labs/Finder-Forge/helpers/open_in_editor.sh): generic editor launcher
- [workflows](/Users/linkary/Codes/Labs/Finder-Forge/workflows): exported Automator workflow bundles

## Validation

Useful commands:

```sh
./install.sh
/System/Library/CoreServices/pbs -read_bundle "$HOME/Library/Services/Open in Cursor.workflow"
```
