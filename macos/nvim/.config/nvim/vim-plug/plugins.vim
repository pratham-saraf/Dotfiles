" auto-install vim-plug
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  "autocmd VimEnter * PlugInstall
  "autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/autoload/plugged')
    
    " Git support"
    Plug 'tpope/vim-fugitive'
    " Better Syntax Support"
    Plug 'sheerun/vim-polyglot'
    " File Explorer"
    Plug 'scrooloose/NERDTree'
    " Auto pairs for '(' '[' '{'
    Plug 'jiangmiao/auto-pairs'
    " Discord Presence"
    Plug 'andweeb/presence.nvim'
    "Airline"
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'    
    "Color Picker"
    Plug 'KabbAmine/vCoolor.vim'
    "fzf"
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    "Auto-complete"
    Plug 'neoclide/coc.nvim', {'branch': 'master', 'do': 'yarn install --frozen-lockfile'}
    "Themes"
    Plug 'Mangeshrex/everblush.vim'
    "Copilot"
    Plug 'github/copilot.vim'    
    "Dracula theme"
    Plug 'dracula/vim'
    "icons"
    Plug 'ryanoasis/vim-devicons'
    "md preview"
    Plug 'iamcco/markdown-preview.nvim'
    " Remote SSH editing (no remote binary needed)
    Plug 'stevearc/oil.nvim'
    " Keybind overlay / cheatsheet popup
    Plug 'folke/which-key.nvim'
    " Side-by-side diff viewer
    Plug 'nvim-lua/plenary.nvim'
    Plug 'sindrets/diffview.nvim'
    " Claude Code inside Neovim
    Plug 'folke/snacks.nvim'
    Plug 'coder/claudecode.nvim'
    call plug#end()

"Config Section

if (has("termguicolors"))
 set termguicolors
endif
syntax enable
colorscheme dracula
