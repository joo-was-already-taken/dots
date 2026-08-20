HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_history"

HISTSIZE=5000
SAVEHIST=5000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

BREW_PREFIX=$(brew --prefix)
if [ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

setopt AUTO_CD
setopt NO_BEEP
setopt INTERACTIVE_COMMENTS

alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias j=just
alias tree='eza --tree --icons=auto'
alias ls='eza --icons=auto'
alias la='ls -a'
alias ll='ls -lah'

bindkey -v
bindkey '^Y' autosuggest-accept
KEYTIMEOUT=1

eval "$(starship init zsh)"

if [ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

if [[ "$OSTYPE" == darwin* ]]; then
  export PATH="$HOME/Applications:$PATH"
fi
