#!/usr/bin/env bash
#
# Bootstrap script for walarch's Arch + Hyprland dotfiles.
# Built from an actual audit of the reference machine (pacman -Qqen /
# -Qqem, systemctl, gsettings, sddm config, etc.) rather than guessed
# from config files alone — see audit.sh to regenerate that data if
# this ever needs to be refreshed.
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
log "Installing all packages (official repos + AUR, via yay)..."
# This list is the literal explicit-install set from the reference
# machine (pacman -Qqen + pacman -Qqem), not a guess from config files.

PACKAGES=(
    # Kernels / microcode — amd-ucode is AMD-specific; swap for
    # intel-ucode if this is ever run on an Intel machine.
    base base-devel linux linux-firmware linux-lts amd-ucode

    # Hyprland desktop
    hyprland waybar awww hypridle hyprlock wlogout wofi swaync hyprshot
    xdg-desktop-portal-hyprland grim slurp
    xdg-user-dirs

    # Terminal / shell / editor
    kitty zsh tmux neovim stow xterm

    # zsh plugins (zsh-vi-mode-git specifically, not the stable zsh-vi-mode)
    zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode-git

    # CLI tools
    eza fastfetch fzf yazi wl-clipboard ripgrep fd zoxide tldr
    bind time strace rsync wget unzip zip 7zip openbsd-netcat nload
    htop btop man-db github-cli jq
    brightnessctl playerctl pacman-contrib

    # Dev / build tooling (nvim + your C projects)
    clang cmake ctags lazygit criterion cjson swig libxcrypt-compat

    # Java / JetBrains
    jdk-openjdk jdk17-openjdk jetbrains-toolbox

    # NOTE: "code" is VS Code. On the reference machine this resolved as
    # a native (non-AUR) package, which usually means a third-party
    # binary repo (commonly chaotic-aur) is configured in pacman.conf.
    # Without that repo, yay will try to build it from the AUR under
    # some other package name and may fail outright. Verify this
    # resolves before trusting it — see the closing notes.
    code

    # Audio / network stack
    pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber
    networkmanager alsa-utils dnsmasq iptables openssh

    # Desktop essentials / theming
    sddm sddm-silent-theme gnome-keyring seahorse nautilus
    qt5ct qt6-wayland qt6ct kvantum zenity flatpak flatpak-xdg-utils
    gimp

    # Fonts
    ttf-jetbrains-mono-nerd ttf-roboto-mono-nerd otf-comicshanns-nerd
    ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji
    ttf-google-sans ttf-rubik-vf

    # Filesystem / disk / boot
    dosfstools ntfs-3g efibootmgr zram-generator

    # Virtualization
    qemu-full virt-manager virt-viewer vde2

    # Media
    vlc vlc-plugins-all kdenlive gst-libav gst-plugins-bad gst-plugins-ugly
    webkit2gtk-4.1 resvg

    # Database
    postgresql

    # GPU (AMD-specific — Vega/Renoir on the reference machine; swap for
    # the Intel/Nvidia equivalents on different hardware)
    vulkan-radeon opencl-mesa clinfo

    # Dev tool version managers that DO have proper packages
    # (SDKMAN doesn't — that's handled separately below)
    nvm miniconda3

    # Misc apps
    blanket qbittorrent libreoffice-still zathura zathura-pdf-mupdf
    firefox pavucontrol anydesk-bin localsend
)

yay -S --needed --noconfirm "${PACKAGES[@]}"

# ---------------------------------------------------------------------------
log "Enabling system services..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable sddm
sudo systemctl enable libvirtd
sudo systemctl enable fstrim.timer
sudo systemctl enable systemd-networkd systemd-networkd-wait-online systemd-resolved
sudo systemctl enable systemd-timesyncd

# ---------------------------------------------------------------------------
log "Setting up PostgreSQL..."
if [ ! -d /var/lib/postgres/data ] || [ -z "$(ls -A /var/lib/postgres/data 2>/dev/null)" ]; then
    sudo -iu postgres initdb -D /var/lib/postgres/data
else
    log "  data directory already initialized, skipping initdb"
fi
sudo systemctl enable --now postgresql

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
echo "Things that genuinely need your input, not guessed:"
echo "  - 'code' (VS Code) resolved as a native package on the reference"
echo "    machine, which usually means a third-party repo (e.g. chaotic-aur)"
echo "    is configured in pacman.conf. This script doesn't set that up —"
echo "    if 'yay -S code' fails here, that's why."
echo "  - SDDM: the outer theme (silent) is now linked, but I don't have"
echo "    /usr/share/sddm/themes/silent/theme.conf, which is what actually"
echo "    selects the everforest color preset inside that theme. Paste that"
echo "    file and I'll track it too."
echo "  - qt5ct/qt6ct: installed, but no config file existed to restore —"
echo "    open qt5ct once and pick a style."
echo "  - zram-generator.conf isn't captured — if you customized it beyond"
echo "    defaults, paste /etc/systemd/zram-generator.conf and I'll add it."
echo "  - Confirm your wallpaper images landed at ~/Pictures/Wallpapers/"
echo "  - Reboot (or log out/in) so the shell, SDDM, GTK theme, and service"
echo "    changes all take effect"
