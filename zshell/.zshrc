# Set app2unit to use UWSM's slices
APP2UNIT_SLICES="a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice"

# Run fastfetch only in interactive shells
if [ -t 0 ]; then
    fastfetch
fi

# Set the directory for zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi


# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"


# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found


# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q


# Initialize oh-my-posh (local vendored theme — no remote fetch at shell start, D-03)
eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/catppuccin.omp.json")"


# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region


# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups


# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'


# Aliases
alias ls='ls -lah --color'
alias vim='nvim'
alias c='clear'
alias codium='codium --ozone-platform=wayland'
alias zed='~/.local/bin/zed'
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Path
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Source
# source /usr/share/nvm/init-nvm.sh # node version manager
export NVM_DIR="$HOME/.config/nvm"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Lazy-load nvm/bun (D-04) — nvm sourcing measured at ~53% of shell-init time
# (zprof: nvm_auto cumulative 53.52%); defer until first invocation instead of
# paying the cost on every interactive shell start.
lazy_load_nvm() {
    unset -f nvm node npm npx bun 2>/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"  # bun completions
}
for cmd in nvm node npm npx bun; do
    eval "function $cmd() { lazy_load_nvm; $cmd \"\$@\" }"
done

export PATH=$PATH:/home/aorus/.spicetify

. "$HOME/.local/share/../bin/env"
