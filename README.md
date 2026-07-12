# dotfiles

Personal configs for an Arch Linux + Hyprland desktop, managed with GNU Stow (https://www.gnu.org/software/stow/).

## Stack

- WM: Hyprland
- Bar: Waybar
- Launcher: Wofi
- Logout menu: wlogout
- Notifications: SwayNC
- Terminal: Kitty
- Multiplexer: tmux
- Shell: Zsh (zsh-vi-mode)
- Editor: Neovim (lazy.nvim)
- Theme: Gruvbox Dark throughout

## Structure

Each top-level folder is a Stow "package" that mirrors its target location under $HOME:

dotfiles/
- hypr/.config/hypr
- kitty/.config/kitty
- nvim/.config/nvim
- waybar/.config/waybar
- wofi/.config/wofi
- wlogout/.config/wlogout
- swaync/.config/swaync
- tmux/.tmux.conf
- zsh/.zshrc

## Fresh install

1. Install prerequisites

   sudo pacman -S stow git

2. Clone this repo

   git clone https://github.com/opu-hossain/dotfiles.git ~/dotfiles
   cd ~/dotfiles

3. Symlink everything into place

   stow hypr kitty nvim waybar wofi wlogout swaync tmux zsh

That's it — all configs are now live symlinks back into this repo.

## Adding a new config later

   cd ~/dotfiles
   mkdir -p NAME/.config/NAME
   mv ~/.config/NAME/* NAME/.config/NAME/
   rmdir ~/.config/NAME
   stow NAME
   git add .
   git commit -m "Add NAME config"
   git push

## Notes

- nvim/lazy-lock.json is tracked intentionally — it pins exact plugin commit hashes so a fresh install reproduces the same plugin versions.
- Neovim's runtime state (shada, undo history, swap files) lives at ~/.local/state/nvim/ and is NOT backed up here — this repo only covers config, not session history.
- If "stow PACKAGE" fails with "existing target is not a symlink," a real file/dir already exists at that path — back it up or remove it first, then re-run stow.
