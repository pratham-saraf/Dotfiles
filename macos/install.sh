#!/usr/bin/env bash
# macOS setup: Homebrew, apps from Brewfile, then symlink every config package into $HOME with GNU stow.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"

brew bundle --file=Brewfile || echo "Some Brewfile entries failed; re-run 'brew bundle' later."
brew list stow >/dev/null 2>&1 || brew install stow

PACKAGES=(zsh bash git tmux nvim kitty starship karabiner claude cursor htop pastehop bin)
for p in "${PACKAGES[@]}"; do
  # --adopt would overwrite repo files with existing ones; back up conflicts instead.
  stow -n -v -t "$HOME" "$p" 2>&1 | sed -n 's/.*existing target is neither a link nor a directory: //p;s/.*over existing target \(.*\) since.*/\1/p' |
    while read -r f; do [ -e "$HOME/$f" ] && mv "$HOME/$f" "$HOME/$f.pre-dotfiles" && echo "backed up ~/$f"; done
  stow -v -t "$HOME" "$p"
done

defaults import com.amethyst.Amethyst amethyst/com.amethyst.Amethyst.plist 2>/dev/null || true
[ -f "$HOME/.ssh/config" ] || { mkdir -p "$HOME/.ssh"; cp ssh/.ssh/config.example "$HOME/.ssh/config"; chmod 600 "$HOME/.ssh/config"; }

# Neovim plugins (vim-plug)
command -v nvim >/dev/null && nvim --headless +PlugInstall +qall || true
echo "Done. Restore SSH keys and the full ~/.ssh/config from the private backup, then: gh auth login"
