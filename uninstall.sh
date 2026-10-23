#!/bin/sh
# Remove Opal's links (only links that point into this repo) and, with
# --system, the login-screen entry. Packages, fonts and settings are kept;
# the commands to remove those are printed at the end.
set -eu

REPO=$(cd "$(dirname "$0")" && pwd)

if [ "${1:-}" = "--system" ]; then
    rm -f /usr/share/wayland-sessions/niri-opal.desktop
    echo "Removed /usr/share/wayland-sessions/niri-opal.desktop"
    exit 0
fi

for dest in \
    "$HOME/.config/quickshell/opal" \
    "$HOME/.config/niri/opal.kdl" \
    "$HOME/.config/systemd/user/niri-opal.service" \
    "$HOME/.config/systemd/user/opal-shell.service" \
    "$HOME/.config/systemd/user/dunst.service.d/opal.conf" \
    "$HOME/.local/bin/niri-opal-session"; do
    if [ -L "$dest" ] && case "$(readlink "$dest")" in "$REPO"/*) true ;; *) false ;; esac; then
        rm "$dest"
        echo "removed  $dest"
    fi
done
rmdir "$HOME/.config/systemd/user/dunst.service.d" 2>/dev/null || true
systemctl --user daemon-reload

cat <<EOF

Still there (remove if you like):
  sudo $REPO/uninstall.sh --system      # login-screen entry
  rm -rf ~/.local/state/opal ~/.cache/opal ~/.local/share/fonts/opal
EOF
