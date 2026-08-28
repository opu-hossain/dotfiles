#!/usr/bin/env bash
#
# Bootstrap script for walarch's Arch + Hyprland dotfiles.
#
# Scope, on purpose: this installs and configures the DESKTOP ENVIRONMENT
# and the DEV ENVIRONMENT (editor, shell, build tooling) — the stuff that's
# tedious and error-prone to redo by hand, and that your configs actively
# depend on to work correctly. It does NOT install personal software
# (IDEs, virtualization, database servers, office/media apps) — see
# optional-packages.txt for that list, installed on your own schedule when
# you actually need something from it.
#
# Run as your normal user (NOT root) from inside the cloned repo:
#
#   ./install.sh
#
# It sudos itself wherever root is actually needed. Safe to re-run —
# every step is written to be idempotent (skips what's already done).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_PACKAGES=(hypr kitty nvim swaync tmux waybar wlogout wofi zsh packman-hooks wallpapers)

log()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31m==> ERROR:\033[0m %s\n' "$1" >&2; exit 1; }

[ "$EUID" -ne 0 ] || die "Don't run this as root — run it as yourself, it sudos when it needs to."
command -v pacman &>/dev/null || die "This script is for Arch Linux (pacman not found)."

# ---------------------------------------------------------------------------
log "Syncing package databases..."
sudo pacman -Sy

# ---------------------------------------------------------------------------
log "Installing base-devel and git (needed to build an AUR helper)..."
sudo pacman -S --needed --noconfirm base-devel git

# ---------------------------------------------------------------------------
# A fresh Arch install's default gpg config has no keyserver configured at
# all in some cases, or one that's flaky. AUR builds that carry validpgpkeys
# (wlogout does) need gpg to actually be able to fetch those keys, so this
# has to be sorted before any makepkg build runs — including yay's own.
log "Configuring a reliable GPG keyserver for AUR package signature checks..."
mkdir -p "$HOME/.gnupg"
if ! grep -q "^keyserver" "$HOME/.gnupg/gpg.conf" 2>/dev/null; then
    echo "keyserver hkps://keyserver.ubuntu.com" >> "$HOME/.gnupg/gpg.conf"
fi

import_pgp_key() {
    local keyid="$1"
    local servers=(hkps://keyserver.ubuntu.com hkps://keys.openpgp.org hkp://keyserver.ubuntu.com:80)
    for server in "${servers[@]}"; do
        if gpg --keyserver "$server" --recv-keys "$keyid" &>/dev/null; then
            return 0
        fi
    done
    warn "  could not import PGP key $keyid from any keyserver — a later AUR build may fail on it"
    return 1
}

# wlogout's PGP key specifically — hit this exact failure during testing.
import_pgp_key F4FDB18A9937358364B276E9E25D679AF73C6D2F

# ---------------------------------------------------------------------------
if ! command -v yay &>/dev/null; then
    log "yay not found — building it from the AUR..."
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
else
    log "yay already installed, skipping."
fi

# ---------------------------------------------------------------------------
# The audio stack goes first, in its own isolated transaction. pipewire-jack
# and jack2 both provide "jack" and conflict; if jack2 gets pulled into a
# huge combined transaction as a dependency of something else, pacman hits
# an unresolvable conflict and stalls waiting for input --noconfirm can't
# answer. Installing this stack alone first means nothing else has a chance
# to pull jack2 in ahead of it.
log "Installing audio stack first (avoids a pipewire-jack/jack2 conflict)..."
yay -S --needed --noconfirm pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber alsa-utils

# ---------------------------------------------------------------------------
log "Installing the desktop + dev environment..."

PACKAGES=(
    # Hyprland desktop
    hyprland waybar awww hypridle hyprlock wlogout wofi swaync hyprshot
    xdg-desktop-portal-hyprland grim slurp xdg-user-dirs

    # Terminal / shell / editor
    kitty zsh tmux neovim stow xterm

    # SSH client — needed just to `git clone` this repo over SSH
    openssh

    # zsh plugins (zsh-vi-mode-git specifically, not the stable zsh-vi-mode)
    zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode-git

    # CLI tools your configs/keybinds actually invoke, plus unzip/zip
    # (hard prerequisites for the SDKMAN installer further down)
    eza fastfetch fzf yazi wl-clipboard ripgrep fd zoxide unzip zip
    brightnessctl playerctl pacman-contrib

    # Build tooling nvim's LSP/DAP/telescope setup depends on directly
    clang cmake ctags lazygit

    # Networking (NetworkManager only — no dnsmasq/iptables, those were
    # pulled in by the virtualization stack, which is now optional)
    networkmanager

    # Desktop essentials / theming
    sddm sddm-silent-theme gnome-keyring nautilus qt5ct qt6-wayland qt6ct

    # The one font your configs actually reference (kitty.conf)
    ttf-jetbrains-mono-nerd

    # GPU (AMD-specific — Vega/Renoir on the reference machine; swap for
    # the Intel/Nvidia equivalents on different hardware)
    vulkan-radeon opencl-mesa

    # Dev tool version managers that have proper packages
    # (SDKMAN doesn't — that's handled separately below)
    nvm miniconda3

    # Your actual browser
    firefox pavucontrol
)

yay -S --needed --noconfirm "${PACKAGES[@]}"

# ---------------------------------------------------------------------------
log "Enabling system services..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable sddm

# ---------------------------------------------------------------------------
log "Enabling user services..."
systemctl --user enable --now wireplumber.service pipewire.socket pipewire-pulse.socket
systemctl --user enable --now xdg-user-dirs.service
systemctl --user enable --now gnome-keyring-daemon.socket p11-kit-server.socket

# ---------------------------------------------------------------------------
log "Setting zsh as your default shell..."
if [ "$SHELL" != "$(command -v zsh)" ]; then
    chsh -s "$(command -v zsh)"
else
    log "  already the default shell, skipping."
fi

# ---------------------------------------------------------------------------
log "Setting GTK theme (matches the reference machine's gsettings exactly)..."
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || \
    warn "  gsettings failed — dconf may need a re-login to initialize, try again after rebooting"
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'default' 2>/dev/null || true

# ---------------------------------------------------------------------------
log "Stowing dotfiles packages..."
cd "$DOTFILES_DIR"
for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        stow --restow "$pkg"
        log "  stowed: $pkg"
    else
        warn "  package '$pkg' not found in repo, skipping"
    fi
done

# ---------------------------------------------------------------------------
log "Making scripts executable..."
chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true

# ---------------------------------------------------------------------------
log "Adding pacman HookDir entry (instant waybar update-badge refresh)..."
if ! grep -q "^HookDir" /etc/pacman.conf; then
    sudo sed -i "/^\[options\]/a HookDir = $HOME/.config/packman-hooks/" /etc/pacman.conf
    log "  added — worth a quick look at /etc/pacman.conf to confirm it landed right"
else
    warn "  /etc/pacman.conf already has a HookDir line — left it alone, check it points at the right place"
fi

# ---------------------------------------------------------------------------
log "Linking the SDDM theme config..."
if [ -f "$DOTFILES_DIR/sddm/sddm.conf.d/theme.conf" ]; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo ln -sf "$DOTFILES_DIR/sddm/sddm.conf.d/theme.conf" /etc/sddm.conf.d/theme.conf
    log "  linked — /etc/sddm.conf.d/theme.conf now points at the repo"
else
    warn "  sddm/sddm.conf.d/theme.conf not found in repo, skipping"
fi

# ---------------------------------------------------------------------------
log "Installing SDKMAN (no pacman/AUR package exists for this one)..."
if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
else
    warn "  SDKMAN already present at ~/.sdkman, skipping"
fi

# ---------------------------------------------------------------------------
log "Done."
echo ""
echo "This installed the desktop + dev environment only. Your other"
echo "software (IDEs, virtualization, database, office/media apps) is"
echo "listed in optional-packages.txt — install it on your own schedule:"
echo ""
echo "  yay -S --needed \$(grep -v '^#' optional-packages.txt)"
echo ""
echo "Things that genuinely need your input, not guessed:"
echo "  - 'code' (VS Code, in optional-packages.txt) resolved as a native"
echo "    package on the reference machine, which usually means a"
echo "    third-party repo (e.g. chaotic-aur) is configured in pacman.conf."
echo "    This script doesn't set that up — if it fails to install later,"
echo "    that's why."
echo "  - SDDM: the outer theme (silent) is now linked, but I don't have"
echo "    /usr/share/sddm/themes/silent/theme.conf, which is what actually"
echo "    selects the everforest color preset inside that theme. Paste that"
echo "    file and I'll track it too."
echo "  - qt5ct/qt6ct: installed, but no config file existed to restore —"
echo "    open qt5ct once and pick a style."
echo "  - Confirm your wallpaper images landed at ~/Pictures/Wallpapers/"
echo "  - Reboot (or log out/in) so the shell, SDDM, GTK theme, and service"
echo "    changes all take effect"
