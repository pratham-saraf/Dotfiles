# Homebrew (Apple Silicon: /opt/homebrew, Intel: /usr/local)
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)" || { [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"; }

# ── Plugins ──────────────────────────────────────────────────────────────────
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# ── Prompt ───────────────────────────────────────────────────────────────────
eval "$(starship init zsh)"
function set_win_title(){
    echo -ne "\033]0; $USER@$HOST:${PWD/$HOME/~} \007"
}
precmd_functions+=(set_win_title)

# ── Path ─────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# ── NVM ──────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ── FZF ──────────────────────────────────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS="
--layout=reverse
--info=inline
--height=80%
--multi
--preview-window=:nohidden
--preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
--color='hl:148,hl+:154,pointer:032,marker:010,bg+:237,gutter:008'
--prompt='∼ ' --pointer='▶' --marker='✓'
--bind '?:toggle-preview'
--bind 'ctrl-a:select-all'
--bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'
--bind 'ctrl-e:execute(echo {+} | xargs -o nvim)'
--bind 'ctrl-v:execute(code {+})'
"

# ── Zoxide ───────────────────────────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── Completion ───────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' menu select=2
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zcache
zstyle ':completion:*:descriptions' format '%U%F{cyan}%d%f%u'

# ── Options ──────────────────────────────────────────────────────────────────
unsetopt correct
setopt extendedglob
setopt nocaseglob
setopt rcexpandparam
setopt nocheckjobs
setopt numericglobsort
setopt nobeep
setopt appendhistory
setopt histignorealldups
setopt autocd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

HISTFILE=~/.zhistory
HISTSIZE=50000
SAVEHIST=10000

# ── Key bindings ─────────────────────────────────────────────────────────────
bindkey -e
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
if [[ -n "${terminfo[kcuu1]}" ]]; then
  autoload -U up-line-or-beginning-search
  zle -N up-line-or-beginning-search
  bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
fi
if [[ -n "${terminfo[kcud1]}" ]]; then
  autoload -U down-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
fi

# ── Aliases — Navigation ──────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# ── Aliases — Listing (eza = modern exa) ─────────────────────────────────────
alias ls='eza -lah --color=always --group-directories-first --sort=modified'
alias la='eza -ahl --color=always --group-directories-first | bat'
alias lr='eza -aR --color=always --group-directories-first | bat'
alias l='eza -a --color=always --group-directories-first | bat'
alias ld='eza -l --color=always --group-directories-first | bat'
alias l.="eza -a | grep '^\\.'"

# ── Aliases — Editor ─────────────────────────────────────────────────────────
alias nv='nvim'
alias v='nvim'

# ── Aliases — Git ────────────────────────────────────────────────────────────
alias gst='git status'
alias gc='git commit'
alias ga='git add .'
alias gps='git push'
alias gpl='git pull'
alias gph='git log --graph --oneline --all'

# ── Aliases — Python venv ────────────────────────────────────────────────────
alias env='python3 -m venv .venv && echo "created env" && source .venv/bin/activate'

# ── Aliases — Common utils ───────────────────────────────────────────────────
alias c='clear'
alias e='exit'
alias h='htop'
alias tarnow='tar -acf'
alias untar='tar -zxvf'
alias wget='wget -c'
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias sz='du -sh ./* | sort -h'

# ── Functions ─────────────────────────────────────────────────────────────────
touch2() { mkdir -p "$(dirname "$1")" && touch "$1"; }

ex() {
  if [ -f "$1" ]; then
    case $1 in
      *.tar.bz2)  tar xjf "$1"   ;;
      *.tar.gz)   tar xzf "$1"   ;;
      *.bz2)      bunzip2 "$1"   ;;
      *.rar)      unrar x "$1"   ;;
      *.gz)       gunzip "$1"    ;;
      *.tar)      tar xf "$1"    ;;
      *.tbz2)     tar xjf "$1"   ;;
      *.tgz)      tar xzf "$1"   ;;
      *.zip)      unzip "$1"     ;;
      *.Z)        uncompress "$1";;
      *.7z)       7z x "$1"      ;;
      *.tar.xz)   tar xf "$1"    ;;
      *.tar.zst)  unzstd "$1"    ;;
      *)          echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Paste-safe URL quoting
autoload -U url-quote-magic bracketed-paste-magic
zle -N self-insert url-quote-magic
zle -N bracketed-paste bracketed-paste-magic
pasteinit() { OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}; zle -N self-insert url-quote-magic; }
pastefinish() { zle -N self-insert $OLD_SELF_INSERT; }
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)

# ── sshnvim — pick host via fzf, then open folder in nvim oil ────────────────
sshnvim() {
  local host
  host=$(grep -E '^Host ' ~/.ssh/config | grep -v '*' | awk '{print $2}' | fzf --prompt="SSH host > " --height=40%)
  [[ -z "$host" ]] && return

  # extract user from ssh config for this host
  local user
  user=$(awk "/^Host $host\$/{found=1} found && /User/{print \$2; exit}" ~/.ssh/config)
  [[ -z "$user" ]] && user="ubuntu"

  local folder
  folder=$(ssh "$host" 'find /home /opt /srv /var/www 2>/dev/null -maxdepth 4 -type d | sort' 2>/dev/null \
    | fzf --prompt="Folder on $host > " --height=60%)
  [[ -z "$folder" ]] && folder="/home/$user"

  # normalize: collapse double slashes, strip trailing slash, ensure leading slash
  folder=$(echo "$folder" | sed 's|//|/|g; s|/$||')
  [[ "$folder" != /* ]] && folder="/$folder"

  local url="oil-ssh://${user}@${host}${folder}/"
  echo "Opening: $url"
  nvim "$url"
}

# Tab complete SSH hosts for oil-ssh:// and plain ssh
_ssh_hosts() {
  local hosts
  hosts=($(grep -E '^Host ' ~/.ssh/config | grep -v '*' | awk '{print $2}'))
  compadd -a hosts
}
compdef _ssh_hosts sshnvim

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# opencode
export PATH=$HOME/.opencode/bin:$PATH
# Account A — current default
alias claude-a='claude'

# Account B — isolated
alias claude-b='CLAUDE_CONFIG_DIR=~/.claude-b claude'

alias claude-p='CLAUDE_CONFIG_DIR=~/.claude-p claude'
alias claude-pp='CLAUDE_CONFIG_DIR=~/.claude-pp claude'

# Added by codebase-memory-mcp install
export PATH="$HOME/.local/bin:$PATH"
