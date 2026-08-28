# dotfiles

Personal configs and bootstrap installer for an Arch Linux + Hyprland desktop environment, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Stack

- **WM:** Hyprland
- **Bar:** Waybar
- **Launcher:** Wofi
- **Logout menu:** wlogout
- **Notifications:** SwayNC
- **Terminal:** Kitty
- **Shell:** Zsh (`zsh-vi-mode`)
- **Editor:** Neovim (`lazy.nvim`)
- **Theme:** Everforest / Adwaita Dark

## Structure

Each top-level directory is a Stow package mirroring its target location under `$HOME`:

```text
dotfiles/
├── hypr/.config/hypr/
├── kitty/.config/kitty/
├── nvim/.config/nvim/
├── swaync/.config/swaync/
├── tmux/.tmux.conf
├── waybar/.config/waybar/
├── wallpapers/Pictures/Wallpapers/
├── wlogout/.config/wlogout/
├── wofi/.config/wofi/
├── zsh/.zshrc
├── install.sh
└── optional-packages.txt
````

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
* Installs the desktop environment (Hyprland, Waybar, SDDM, SwayNC, fonts, etc.).
* Installs CLI tools, development runtimes (`nvm`, `miniconda3`), and SDKMAN.
* Stows all configuration packages to `$HOME`.
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
* **Neovim state:** `nvim/lazy-lock.json` is tracked to pin plugin commit hashes. Runtime state (undo history, shada files, swap) is stored locally at `~/.local/state/nvim/` and ignored.
* **Script Idempotency:** `install.sh` is safe to re-run anytime—it automatically skips packages and configurations that are already set up.

