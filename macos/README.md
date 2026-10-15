# macOS dotfiles

```sh
git clone https://github.com/pratham-saraf/Dotfiles.git ~/Dotfiles
~/Dotfiles/macos/install.sh
```

`install.sh` installs Homebrew and everything in `Brewfile`, then symlinks each folder into `$HOME` with GNU stow (existing files are renamed to `*.pre-dotfiles`).

| Package | Files |
|---|---|
| zsh, bash | `.zshrc`, `.bashrc` |
| git | `.gitconfig` (gh as credential helper), global `ignore` |
| tmux | `.tmux.conf` |
| nvim | `init.vim`, vim-plug plugin list, coc settings |
| kitty, starship, karabiner | terminal, prompt, keyboard remaps |
| claude | Claude Code `settings.json`, `website-to-cli` skill |
| cursor | MCP servers, `/deslop` command |
| htop, pastehop | htop layout, pastehop keybinding |
| bin | `~/bin/claudepaste` |
| amethyst | window-manager prefs (imported with `defaults import`) |
| ssh | `config.example` — GitHub hosts only |

Not in this repo (private): SSH keys, the full `~/.ssh/config` with server entries, `.env` files, cloud credentials. Restore those from the private backup.
