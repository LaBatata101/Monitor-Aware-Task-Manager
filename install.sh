#!/usr/bin/env bash
set -euo pipefail

APPLET_ID="com.labatata.monitortasks"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
MANIFEST="$BUILD_DIR/install_manifest.txt"
# The applet is a compiled C++ plugin, so it must live where plasmashell finds Qt plugins.
INSTALL_PREFIX="/usr"
PLUGIN_FILE="$INSTALL_PREFIX/lib/qt6/plugins/plasma/applets/$APPLET_ID.so"

usage() {
    cat <<EOF
Usage: ./install.sh [option]

Builds the widget and installs it system-wide (uses sudo).
Re-run after every Plasma update so the fork keeps matching libtaskmanager.

Options:
  --install          Build and install or update the plasmoid (default)
  --restart-plasma  Install or update, then restart Plasma Shell
  --remove          Remove the installed plasmoid
  -h, --help        Show this help
EOF
}

install_or_update() {
    if [[ ! -f "$SCRIPT_DIR/CMakeLists.txt" ]]; then
        echo "Error: CMakeLists.txt not found at $SCRIPT_DIR/CMakeLists.txt" >&2
        return 1
    fi

    if [[ -f "$PLUGIN_FILE" ]]; then
        echo "Updating $APPLET_ID..."
    else
        echo "Installing $APPLET_ID..."
    fi

    cmake -S "$SCRIPT_DIR" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DBUILD_TESTING=OFF
    cmake --build "$BUILD_DIR" -j"$(nproc)"
    sudo cmake --install "$BUILD_DIR"
    echo "Installed files listed in $MANIFEST."
}

remove_plasmoid() {
    if [[ ! -f "$PLUGIN_FILE" ]]; then
        echo "$APPLET_ID is not installed at $PLUGIN_FILE."
        return 0
    fi

    if [[ ! -f "$MANIFEST" ]]; then
        echo "Error: install manifest not found at $MANIFEST; run ./install.sh first to regenerate it." >&2
        return 1
    fi

    echo "Removing $APPLET_ID..."
    xargs -d '\n' sudo rm -f < "$MANIFEST"
    sudo rmdir --ignore-fail-on-non-empty "$INSTALL_PREFIX/share/plasma/plasmoids/com.labatata.monitoricontasks" 2>/dev/null || true
    echo "Removed files listed in $MANIFEST."
}

restart_plasma() {
    if command -v kquitapp6 >/dev/null 2>&1; then
        kquitapp6 plasmashell || true
    else
        killall plasmashell || true
    fi

    if command -v kstart >/dev/null 2>&1; then
        kstart plasmashell >/dev/null 2>&1
    elif command -v kstart6 >/dev/null 2>&1; then
        kstart6 plasmashell >/dev/null 2>&1
    else
        nohup plasmashell >/dev/null 2>&1 &
    fi
}

main() {
    local action="${1:---install}"

    case "$action" in
        --install)
            install_or_update
            ;;
        --restart-plasma)
            install_or_update
            restart_plasma
            echo "Restarted Plasma Shell."
            ;;
        --remove)
            remove_plasmoid
            ;;
        -h|--help)
            usage
            ;;
        *)
            usage >&2
            return 2
            ;;
    esac
}

main "$@"
