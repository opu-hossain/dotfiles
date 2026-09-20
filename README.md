# dotfiles

Personal configs and bootstrap installer for an Arch Linux + Hyprland desktop environment, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Stack

- **WM:** Hyprland — config is Lua (`hyprland.lua`, Hyprland ≥ 0.55), migrated off the legacy hyprlang `.conf` syntax; the pre-migration files are kept alongside as `*.conf.bak`
- **Shell (bar, launcher, power menu, notifications):** [Quickshell](https://quickshell.outfoxxed.me) — a custom config, `walarch-shell`, replacing Waybar, Wofi, wlogout, and SwayNC with one cohesive UI
- **Idle / lock:** hypridle + hyprlock
- **Terminal:** Kitty
- **Shell:** Zsh (`zsh-vi-mode`)
- **Editor:** Neovim (`lazy.nvim`)
- **Theme:** Everforest / Adwaita Dark

## Structure

Each top-level directory is a Stow package mirroring its target location under `$HOME`:

```text
dotfiles/
├── environmentd/.config/environment.d/
├── hypr/.config/hypr/
├── kitty/.config/kitty/
├── nvim/.config/nvim/
├── packman-hooks/.config/packman-hooks/
├── quickshell/.config/quickshell/walarch-shell/
├── tmux/.tmux.conf
├── wallpapers/Pictures/Wallpapers/
├── zsh/.zshrc
├── install.sh
└── optional-packages.txt
````

---

## Quickshell (`walarch-shell`)

A single Quickshell (QML) config that replaces Waybar, Wofi, wlogout, and SwayNC:

- **Bar** (`shell.qml`): workspaces, focused window title, CPU/RAM, pending package-update count, network throughput, volume, a power button, and the clock.
- **Launcher** (`Launcher.qml`): vim-navigable app search, toggled via `qs -c walarch-shell ipc call launcher toggle` (bound to `$mainMod + A` / `$mainMod + R`).
- **Power menu** (`PowerOverlay.qml`): lock / logout / suspend / reboot / shutdown, with a confirmation step for the destructive actions when windows are still open. Toggled via `qs -c walarch-shell ipc call power toggle` (bound to `$mainMod + M`).
- **Notifications** (`Notifications.qml`): toast notifications via Quickshell's built-in `NotificationServer` — no separate notification daemon needed or wanted alongside it.
- The `packman-hooks` pacman hook fires `qs ... ipc call updates refresh` after every package transaction, so the update-count pill stays current without polling.

---

## Quick Start (Automated Install)

On a fresh Arch Linux minimal installation, log in as your regular user (do **not** run as `root`):

```bash
# 1. Install git & clone repo
sudo pacman -S --needed git
git clone https://github.com/opu-hossain/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Make the installer executable & run
chmod +x install.sh
./install.sh
```

### What `install.sh` handles automatically

* Installs `yay` (AUR helper) and base build tools.
* Sets up the PipeWire audio stack (resolving `pipewire-jack` / `jack2` conflicts).
* Installs the desktop environment (Hyprland, Quickshell, hypridle/hyprlock, SDDM, fonts, etc.).
* Installs CLI tools and development runtimes/toolchains (`rustup`, `uv`, `miniconda3`), plus `nvm` and SDKMAN from upstream.
* Stows all configuration packages to `$HOME`, including `environmentd`'s dev-tool environment variables.
* Creates the dev-tool cache directories those environment variables point at (see Notes below).
* Configures system/user services, GTK themes, and default shell (`zsh`).

---

## Post-Install Steps

1. **Reboot your system** to initialize SDDM, GTK themes, and system services properly:

```bash
sudo reboot
```

2. **Optional Software:** Personal software (IDEs, virtualization, database tools, etc.) is kept out of the base installer to keep it lean. Install additional packages as needed:

```bash
yay -S --needed $(grep -v '^#' optional-packages.txt)
```

---

## Adding a New Config

To track a new configuration folder with Stow:

```bash
cd ~/dotfiles
mkdir -p NAME/.config/NAME
mv ~/.config/NAME/* NAME/.config/NAME/
rmdir ~/.config/NAME
stow NAME
git add .
git commit -m "Add NAME config"
git push
```

---

## Notes

* **Stow conflicts:** If `stow` throws an `existing target is not a symlink` error, a real file or directory exists at that location. Back it up or remove it first, then re-run `stow <package>`.
* **Dev tool directories:** `environmentd/.config/environment.d/dev.conf` points Rust (`RUSTUP_HOME`/`CARGO_HOME`), Node (`NVM_DIR`/npm cache), Gradle, Dart pub, `uv`, and the Android SDK at paths under `/data/home/`. `install.sh` creates those directories automatically, but that assumes `/data` is already mounted on the machine — mount it first, or edit `dev.conf` to point somewhere else, if you're setting this up on different hardware.
* **nvm:** installed straight from the upstream install script into `$NVM_DIR` rather than via the `nvm` pacman package, which installs to a systemwide path `.zshrc` doesn't look at.
* **Android SDK:** the SDK itself isn't installed automatically (accepting licenses needs an interactive `sdkmanager` run) — `install.sh` only prepares the directory at `ANDROID_HOME`.
* **Hyprland Lua config:** `hypr/hyprland.lua` is loaded automatically instead of `hyprland.conf` on Hyprland ≥ 0.55. The pre-migration hyprlang files are kept as `*.conf.bak` for reference. One windowrule (`firefox-transparency`) didn't auto-convert during that migration — see the TODO comment in `modules/windowrules.lua` and re-add it by hand as an `hl.window_rule({...})`.
* **Neovim state:** `nvim/lazy-lock.json` is tracked to pin plugin commit hashes. Runtime state (undo history, shada files, swap) is stored locally at `~/.local/state/nvim/` and ignored.
* **Script Idempotency:** `install.sh` is safe to re-run anytime—it automatically skips packages and configurations that are already set up.
