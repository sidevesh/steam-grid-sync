#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    --help|-h) printf 'Usage: bash install.sh [--cli-only]\n'; exit 0 ;;
    --cli-only|'') ;;
    *) printf 'Usage: bash install.sh [--cli-only]\n' >&2; exit 2 ;;
esac
if (( $# > 1 )); then
    printf 'Usage: bash install.sh [--cli-only]\n' >&2
    exit 2
fi
if [[ "$(uname -s)" != Linux ]]; then
    printf 'The installer requires a Linux client.\n' >&2
    exit 2
fi
if (( EUID == 0 )); then
    printf 'Run this installer from your Steam user account, without sudo.\n' >&2
    exit 2
fi
if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4) )); then
    printf 'Steam Grid Sync requires Bash 4.4 or newer.\n' >&2
    exit 2
fi

for program in ssh sftp ssh-keygen ssh-keyscan; do
    if ! command -v "$program" >/dev/null; then
        printf 'Missing %s. Install the OpenSSH client package and try again.\n' "$program" >&2
        exit 2
    fi
done

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
binary="$HOME/.local/bin/steam-grid-sync"
data_home="${XDG_DATA_HOME:-}"
[[ "$data_home" == /* ]] || data_home="$HOME/.local/share"
launcher="$data_home/applications/steam-grid-sync.desktop"

if [[ "${1:-}" != --cli-only ]]; then
    if ! command -v zenity >/dev/null; then
        printf 'Install Zenity for the desktop launcher, or rerun with --cli-only.\n' >&2
        exit 2
    fi
    if [[ "$binary" == *[$'\n\r\t=']* ]]; then
        printf 'The executable path cannot be represented in a desktop launcher. Use --cli-only.\n' >&2
        exit 2
    fi
fi

install -D -m 0755 -- "$source_dir/steam-grid-sync" "$binary"
printf 'Installed %s\n' "$binary"

if [[ "${1:-}" != --cli-only ]]; then
    # Escape both the desktop-entry string and the quoted Exec argument.
    desktop_exec=${binary//\\/\\\\\\\\}
    desktop_exec=${desktop_exec//\"/\\\\\"}
    desktop_exec=${desktop_exec//\$/\\\\\$}
    desktop_exec=${desktop_exec//\`/\\\\\`}
    desktop_exec=${desktop_exec//%/%%}
    mkdir -p -- "${launcher%/*}"
    cat >"$launcher" <<EOF
[Desktop Entry]
Type=Application
Name=Sync Steam Artwork
Comment=Copy custom artwork from another Steam computer
Exec="$desktop_exec" sync --gui
Icon=steam
Terminal=false
Categories=Game;
Actions=ConnectionSettings;TestConnection;

[Desktop Action ConnectionSettings]
Name=Connection Settings
Exec="$desktop_exec" connection-settings --gui

[Desktop Action TestConnection]
Name=Test Connection
Exec="$desktop_exec" test-connection --gui
EOF
    printf 'Open “Sync Steam Artwork” from your application menu to finish setup.\n'
else
    printf 'Run "%s" init to finish setup.\n' "$binary"
fi
