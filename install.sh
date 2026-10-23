#!/bin/sh
# Opal installer.
#   ./install.sh            link the dotfiles into place, fetch the fonts, then
#                           offer to run the system part with sudo
#   sudo ./install.sh --system
#                           packages + the "Niri (Opal)" login-screen entry
#
# Existing files are moved to ~/.cache/opal/backup-<date>/, never deleted.
# Your regular niri session (~/.config/niri/config.kdl) is not touched.
set -eu

REPO=$(cd "$(dirname "$0")" && pwd)

# ---- system part (root) --------------------------------------------------------
if [ "${1:-}" = "--system" ]; then
    if [ "$(id -u)" -ne 0 ]; then
        echo "The system part needs root:  sudo $0 --system" >&2
        exit 1
    fi
    target_user=${SUDO_USER:-}
    if [ -z "$target_user" ]; then
        echo "Run this through sudo from your normal user, so the session points at your home." >&2
        exit 1
    fi
    target_home=$(getent passwd "$target_user" | cut -d: -f6)

    echo ":: Installing packages"
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y quickshell cliphist wlsunset cava ImageMagick playerctl brightnessctl wl-clipboard
    elif command -v pacman >/dev/null 2>&1; then
        pacman -S --needed quickshell cliphist wlsunset cava imagemagick playerctl brightnessctl wl-clipboard
    else
        echo "   Unknown package manager. Install: quickshell cliphist wlsunset cava imagemagick playerctl brightnessctl wl-clipboard"
    fi

    echo ":: Adding the login session"
    mkdir -p /usr/share/wayland-sessions
    cat > /usr/share/wayland-sessions/niri-opal.desktop <<DESKTOP
[Desktop Entry]
Name=Niri (Opal)
Comment=niri with the Opal liquid-glass shell
Exec=$target_home/.local/bin/niri-opal-session
Type=Application
DesktopNames=niri
DESKTOP
    chmod 644 /usr/share/wayland-sessions/niri-opal.desktop
    echo "   /usr/share/wayland-sessions/niri-opal.desktop"
    exit 0
fi

# ---- user part ---------------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
    echo "Run ./install.sh as your normal user (it will ask for sudo when needed)." >&2
    exit 1
fi

BACKUP="$HOME/.cache/opal/backup-$(date +%Y%m%d-%H%M%S)"

link() {  # link <path in repo> <destination>
    src="$REPO/$1"
    dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "   ok      $dest"
        return
    fi
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mkdir -p "$BACKUP"
        mv "$dest" "$BACKUP/"
        echo "   backup  $dest -> $BACKUP/"
    fi
    ln -s "$src" "$dest"
    echo "   linked  $dest"
}

echo ":: Linking dotfiles"
link quickshell/opal                    "$HOME/.config/quickshell/opal"
link niri/opal.kdl                      "$HOME/.config/niri/opal.kdl"
link systemd/niri-opal.service          "$HOME/.config/systemd/user/niri-opal.service"
link systemd/opal-shell.service         "$HOME/.config/systemd/user/opal-shell.service"
link systemd/dunst.service.d/opal.conf  "$HOME/.config/systemd/user/dunst.service.d/opal.conf"
link bin/niri-opal-session              "$HOME/.local/bin/niri-opal-session"
systemctl --user daemon-reload

echo ":: Fonts (Inter, Material Symbols Rounded)"
FONTS="$HOME/.local/share/fonts/opal"
mkdir -p "$FONTS"
if [ ! -f "$FONTS/MaterialSymbolsRounded.ttf" ]; then
    curl -fL --progress-bar -o "$FONTS/MaterialSymbolsRounded.ttf" \
        'https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf'
fi
if [ ! -f "$FONTS/InterVariable.ttf" ]; then
    tmp=$(mktemp -d)
    curl -fL --progress-bar -o "$tmp/inter.zip" https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip
    unzip -q -o "$tmp/inter.zip" InterVariable.ttf InterVariable-Italic.ttf -d "$FONTS"
    rm -rf "$tmp"
fi
fc-cache -f "$FONTS" >/dev/null
echo "   ok"

echo ":: System part: packages + login-screen entry (needs sudo)"
printf '   Run it now? [Y/n] '
read -r answer || answer=n
case "$answer" in
    n | N) echo "   Skipped. Later:  sudo $REPO/install.sh --system" ;;
    *) sudo sh "$REPO/install.sh" --system ;;
esac

echo
echo "Done. Log out and pick \"Niri (Opal)\" on your login screen."
