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
STOW_PACKAGES=(hypr kitty nvim tmux quickshell environmentd zsh packman-hooks wallpapers)

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
# need gpg to actually be able to fetch those keys, so this has to be sorted
# before any makepkg build runs — including yay's own.
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

# NOTE: wlogout used to need its PGP key imported here explicitly, but it's
# been retired — Quickshell's own power menu (walarch-shell's PowerOverlay.qml)
# now handles lock/logout/suspend/reboot/shutdown, so wlogout is no longer
# installed at all. The helper above is kept around in case a future AUR
# package needs a manual key import.

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
    hyprland quickshell awww hypridle hyprlock hyprshot
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

    # Build tooling nvim's LSP/DAP/telescope/conform setup depends on directly
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

    # Dev tool version managers/toolchains that have proper packages.
    # nvm is deliberately NOT here — it's installed straight from upstream
    # further down so it lands at $NVM_DIR (see environmentd/dev.conf)
    # instead of the pacman package's systemwide path, which .zshrc never
    # looks at. SDKMAN doesn't have a package at all either — also handled
    # separately below.
    rustup uv miniconda3

    # Your actual browser
    firefox pavucontrol
)

yay -S --needed --noconfirm "${PACKAGES[@]}"

# ---------------------------------------------------------------------------
HYPR_VER="$(pacman -Q hyprland 2>/dev/null | awk '{print $2}')"
log "Hyprland version installed: ${HYPR_VER:-unknown} (hypr/hyprland.lua needs Hyprland >= 0.55 for native Lua config support)"

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
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true

# ---------------------------------------------------------------------------
log "Adding pacman HookDir entry (instant Quickshell update-pill refresh)..."
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
# environmentd (stowed above) puts RUSTUP_HOME/CARGO_HOME/NVM_DIR/
# npm_config_cache/GRADLE_USER_HOME/PUB_CACHE/UV_*/ANDROID_* at
# ~/.config/environment.d/dev.conf. Load it now so the rest of this script
# (and the directories/tools it sets up below) agree with .zshrc about
# where those tools actually live — almost all of it is on a /data drive,
# not under $HOME.
log "Loading dev tool env vars from environmentd/dev.conf..."
if [ -f "$HOME/.config/environment.d/dev.conf" ]; then
    set -a
    . "$HOME/.config/environment.d/dev.conf"
    set +a
else
    warn "  dev.conf not found post-stow — falling back to its default paths for the rest of this script"
fi

# ---------------------------------------------------------------------------
log "Creating dev tool cache/home directories referenced by dev.conf..."
if [ -d /data ]; then
    if mkdir -p \
        "${RUSTUP_HOME:-/data/home/dev/rustup}" \
        "${CARGO_HOME:-/data/home/dev/cargo}" \
        "${NVM_DIR:-/data/home/dev/nvm}" \
        "${npm_config_cache:-/data/home/dev/npm}" \
        "${GRADLE_USER_HOME:-/data/home/dev/gradle}" \
        "${PUB_CACHE:-/data/home/dev/pub-cache}" \
        "${UV_CACHE_DIR:-/data/home/dev/uv/cache}" \
        "${UV_TOOL_DIR:-/data/home/dev/uv/share/tools}" \
        "${UV_PYTHON_INSTALL_DIR:-/data/home/dev/uv/share/python}" \
        "${ANDROID_SDK_ROOT:-/data/home/android/sdk}" \
        "${ANDROID_AVD_HOME:-/data/home/android/dot-android/avd}" \
        2>/dev/null
    then
        log "  dev tool directories ready under /data/home/"
    else
        warn "  couldn't create one or more dev tool directories — check permissions on /data"
    fi
else
    warn "/data isn't mounted on this machine. dev.conf points Rust/Node/Gradle/Dart/uv/Android caches under /data/home/ — mount that drive first (or edit environmentd/.config/environment.d/dev.conf to point elsewhere), otherwise those tools won't have anywhere to write."
fi

# ---------------------------------------------------------------------------
log "Installing nvm into \$NVM_DIR (not via pacman — see the note above PACKAGES)..."
NVM_DIR="${NVM_DIR:-/data/home/dev/nvm}"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    mkdir -p "$NVM_DIR"
    NVM_LATEST_TAG="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null \
        | grep -m1 '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST_TAG:-v0.40.1}/install.sh" \
        | NVM_DIR="$NVM_DIR" bash
else
    log "  nvm already installed at $NVM_DIR, skipping."
fi

# ---------------------------------------------------------------------------
log "Setting the default Rust toolchain (rustup)..."
if command -v rustup &>/dev/null; then
    rustup default stable 2>/dev/null || \
        warn "  'rustup default stable' failed — run it yourself once RUSTUP_HOME/CARGO_HOME are set in a new shell"
else
    warn "  rustup not on PATH yet — run 'rustup default stable' yourself in a new shell"
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
echo "  - Dev tool caches (rustup/cargo/nvm/npm/gradle/pub-cache/uv/android)"
echo "    live under /data/home/ per environmentd/dev.conf — make sure that"
echo "    drive is mounted on this machine, or edit dev.conf if your layout"
echo "    differs."
echo "  - The Android SDK itself isn't installed automatically (accepting"
echo "    licenses needs a manual 'sdkmanager' run) — ANDROID_HOME points at"
echo "    /data/home/android/sdk; install the SDK there yourself."
echo "  - hypr/hyprland.lua replaces the old hyprlang .conf files (kept"
echo "    alongside as *.conf.bak for reference) and needs Hyprland >= 0.55."
echo "    One windowrule (firefox-transparency) didn't auto-convert during"
echo "    that migration — see the TODO comment in modules/windowrules.lua"
echo "    and re-add it by hand as an hl.window_rule({...})."
echo "  - Reboot (or log out/in) so the shell, SDDM, GTK theme, and service"
echo "    changes all take effect"
