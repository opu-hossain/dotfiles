# ══════════════════════════════════════════════════════
#  HISTORY
# ══════════════════════════════════════════════════════
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS       # no consecutive duplicate entries
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate when a new one is added
setopt HIST_FIND_NO_DUPS      # don't show dupes when searching history
setopt HIST_REDUCE_BLANKS     # trim superfluous blanks before saving
setopt HIST_EXPIRE_DUPS_FIRST # if history must trim, drop dupes first
setopt HIST_IGNORE_SPACE      # commands starting with space aren't saved
setopt HIST_VERIFY            # show command before executing from history
setopt SHARE_HISTORY          # share history across sessions
setopt APPEND_HISTORY         # append, don't overwrite

# restore some useful emacs bindings in insert mode
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^W' backward-kill-word
bindkey '^H' backward-delete-char
bindkey '^?' backward-delete-char

# edit the current command line in $EDITOR (nvim) from vicmd mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd '^X^E' edit-command-line

# SET MANPAGER
# SET NVIM 
export MANPAGER="nvim +Man!"

# ══════════════════════════════════════════════════════
#  CLIPBOARD  (xclip fallback → wl-copy primary)
# ══════════════════════════════════════════════════════
# Hyprland is Wayland — use wl-clipboard
if command -v wl-copy &>/dev/null; then
    alias copy='wl-copy'
    alias paste='wl-paste'
else
    alias copy='xclip -selection clipboard'
    alias paste='xclip -selection clipboard -o'
fi


# ══════════════════════════════════════════════════════
#  TAB COMPLETION  (with directory selection)
# ══════════════════════════════════════════════════════
autoload -Uz compinit

# only regenerate the completion dump once a day — checking it on every
# shell start is the single biggest avoidable startup cost in zsh
for dump in ~/.zcompdump(N.mh+24); do
    compinit
done
compinit -C

zstyle ':completion:*' menu select                        # arrow-key menu
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"  # colored entries
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'      # case insensitive
zstyle ':completion:*' group-name ''                      # group by category
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'
zstyle ':completion:*:cd:*' ignore-parents parent pwd    # no ../ in cd

# fzf-powered tab if fzf is installed
if command -v fzf &>/dev/null; then
    source /usr/share/fzf/key-bindings.zsh 2>/dev/null
    source /usr/share/fzf/completion.zsh   2>/dev/null

    # Gruvbox fzf colors
    export FZF_DEFAULT_OPTS="
        --color=bg+:#3c3836,bg:#1d2021,spinner:#fb4934,hl:#83a598
        --color=fg:#ebdbb2,header:#83a598,info:#fabd2f,pointer:#fb4934
        --color=marker:#fb4934,fg+:#ebdbb2,prompt:#fabd2f,hl+:#83a598
        --height=40% --layout=reverse --border=sharp
    "
    # ctrl+t = fuzzy file, alt+c = fuzzy cd, ctrl+r = fuzzy history
fi

# enable shift-tab to go backwards in menu
bindkey '^[[Z' reverse-menu-complete


# ══════════════════════════════════════════════════════
#  PLUGINS
# ══════════════════════════════════════════════════════
# guarded so a missing package (fresh install, different machine) doesn't
# throw a "no such file" error on every new shell

# zsh-vi-mode — must load BEFORE any prompt/vcs_info setup below
ZVM_VI_HIGHLIGHT_BACKGROUND=#d79921
ZVM_VI_HIGHLIGHT_FOREGROUND=#1d2021
[[ -f /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# Gruvbox syntax highlighting colors
ZSH_HIGHLIGHT_STYLES[default]='fg=#ebdbb2'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#cc241d,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#d79921,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#b8bb26'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#b8bb26'
ZSH_HIGHLIGHT_STYLES[function]='fg=#b8bb26'
ZSH_HIGHLIGHT_STYLES[command]='fg=#b8bb26'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#8ec07c,italic'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#fb4934'
ZSH_HIGHLIGHT_STYLES[path]='fg=#83a598,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#d79921'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#d79921'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#fabd2f'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#928374,italic'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#d3869b'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#d3869b'

# autosuggestion color (grey, subtle)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#665c54'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ══════════════════════════════════════════════════════
#  PROMPT  (Gruvbox, minimal)
# ══════════════════════════════════════════════════════
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{#d79921}(%b)%f'
setopt PROMPT_SUBST

PROMPT='%F{#458588}%~%f${vcs_info_msg_0_} %F{#98971a}❯%f '

# ══════════════════════════════════════════════════════
#  ALIASES
# ══════════════════════════════════════════════════════
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias vi='nvim'
alias vim='nvim'
alias cls='clear'

# Yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
