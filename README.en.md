# Finder Forge

[中文说明](./README.md)

Finder Forge installs Finder Quick Actions / Services on macOS:

- `New Text File Here`
- `Open in Qoder`
- `Open in Cursor`
- `Open in Code`

They are implemented as Automator `.workflow` bundles and shared shell helpers. The installer copies the workflows to `~/Library/Services` and the helpers to `~/Library/Application Support/FinderForge/helpers`.

## Behavior

- `New Text File Here` creates `untitled.txt` in the current Finder folder.
- If `untitled.txt` already exists, it creates `untitled 2.txt`, `untitled 3.txt`, and so on.
- If exactly one folder is selected, the new file is created inside that folder.
- `New Text File Here` is shown for folder context, not file context.
- Editor actions open the selected file or folder in the requested editor.
- If nothing is selected, editor actions open the current Finder folder or the Desktop.

## Install

For a shareable one-line installer with an Install / Uninstall prompt:

```sh
curl -fsSL https://raw.githubusercontent.com/linkary/finder-forge/main/bootstrap.sh | bash
```

For non-interactive runs:

```sh
curl -fsSL https://raw.githubusercontent.com/linkary/finder-forge/main/bootstrap.sh | bash -s -- install
curl -fsSL https://raw.githubusercontent.com/linkary/finder-forge/main/bootstrap.sh | bash -s -- uninstall
```

`bootstrap.sh` is directly runnable with `bash`; it invokes macOS's built-in `/bin/zsh` internally for the actual installer, so users do not need to install zsh separately.

If you are running from a local checkout, you can still use:

```sh
./install.sh
```

The installer:

- copies the helpers into `~/Library/Application Support/FinderForge/helpers`
- installs `New Text File Here` every time
- installs editor workflows only when the target app exists on this Mac
- copies the full workflow bundles so localized menu resources are preserved
- rewrites the workflow command paths to point at the installed helpers
- asks macOS to rescan Services

To remove everything installed by Finder Forge:

```sh
./install.sh uninstall
```

The bootstrap installer above can also remove everything with the `uninstall` action.

## Configuration

Editor app paths live in [helpers/editor_config.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/editor_config.sh).

Current defaults:

- `Qoder`: `/Applications/Qoder.app`
- `Cursor`: `/Applications/Cursor.app`
- `Visual Studio Code`: `/Applications/Visual Studio Code.app`

If any editor moves, update those paths in [helpers/editor_config.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/editor_config.sh) and rerun `./install.sh`.

## Localization

- Finder Forge ships localized service menu labels for English, Simplified Chinese, and Traditional Chinese.
- Finder uses the current macOS language and falls back to English for unsupported languages.

## Finder Background Limitation

- Generic Finder Services / Quick Actions do not reliably provide a top-level right-click item for empty space in a Finder window.
- This project uses Services, so `New Text File Here` can appear for folders but not as a true empty-space background menu item.
- If you need empty-space background actions, the practical path is a Finder Sync extension or a third-party tool that wraps Finder extension behavior.

## Layout

- [helpers/finder_context.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/finder_context.sh): shared Finder context resolution and Finder UI helpers
- [helpers/editor_config.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/editor_config.sh): shared editor app names and paths for install and launch
- [helpers/create_text_file.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/create_text_file.sh): file creation action
- [helpers/open_in_editor.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/open_in_editor.sh): generic editor launcher
- [workflows](/Users/linkary/Codes/Labs/finder-forge/workflows): exported Automator workflow bundles

## Validation

Useful commands:

```sh
./install.sh
./install.sh uninstall
/System/Library/CoreServices/pbs -read_bundle "$HOME/Library/Services/Open in Cursor.workflow"
```
