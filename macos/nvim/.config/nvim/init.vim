:set number
:set relativenumber
:set autoindent
:set smarttab
" coc.nvim needs Node >=24; point it at the nvm-installed 24.x without
" touching the shell's default Node (still 20.x) used by other projects
let g:coc_node_path = expand('~/.nvm/versions/node/v24.21.0/bin/node')
source $HOME/.config/nvim/vim-plug/plugins.vim
let g:airline_theme='dracula'

let g:NERDTreeShowHidden = 1
let g:NERDTreeMinimalUI = 1
let g:NERDTreeIgnore = []
let g:NERDTreeStatusline = ''
" Automaticaly close nvim if NERDTree is only thing left open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" Ctrl+b: NERDTree locally, Oil when in a remote SSH buffer
nnoremap <silent> <C-b> :call ToggleFileExplorer()<CR>
function! ToggleFileExplorer()
  if expand('%') =~ '^oil-ssh://'
    execute 'Oil ' . expand('%:h')
  else
    NERDTreeToggle
  endif
endfunction

" open new split panes to right and below
set splitright
set splitbelow
" turn terminal to normal mode with escape
tnoremap <Esc> <C-\><C-n>
" start terminal in insert mode
au BufEnter * if &buftype == 'terminal' | :startinsert | endif
" open terminal on ctrl+n
function! OpenTerminal()
  split term://zsh
  resize 10
endfunction
nnoremap <c-n> :call OpenTerminal()<CR>

" use alt+hjkl to move between split/vsplit panels
tnoremap <A-h> <C-\><C-n><C-w>h
tnoremap <A-j> <C-\><C-n><C-w>j
tnoremap <A-k> <C-\><C-n><C-w>k
tnoremap <A-l> <C-\><C-n><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l

nnoremap <C-p> :FZF<CR>
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit'
  \}

"to modify readonly files with w!!"
cnoremap w!! execute 'silent! write !sudo tee % >/dev/null' <bar> edit!

" ── CoC autocomplete ──────────────────────────────────────────────────────────
" Tab to cycle through suggestions
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" gd = go to definition, K = hover docs, gr = references
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <silent> K :call ShowDocumentation()<CR>
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" <leader>rn = rename symbol
nmap <leader>rn <Plug>(coc-rename)
" <leader>f = format file
nmap <leader>f <Plug>(coc-format)

" ── Oil.nvim (remote SSH editing) ────────────────────────────────────────────
lua << EOF
require("oil").setup({
  default_file_explorer = false,
  view_options = { show_hidden = true },
  keymaps = {
    ["<CR>"]  = "actions.select",
    ["<BS>"]  = "actions.parent",
    ["_"]     = "actions.open_cwd",
    ["g."]    = "actions.toggle_hidden",
    ["gs"]    = "actions.change_sort",
    ["gx"]    = "actions.open_external",
    ["g?"]    = "actions.show_help",
    ["q"]     = "actions.close",
  },
})
EOF
" \o to open oil file browser (local or remote)
nnoremap <leader>o :Oil<CR>
" \O to open oil in floating window
nnoremap <leader>O :Oil --float<CR>

" ── which-key.nvim (keybind overlay) ────────────────────────────────────────
lua << EOF
require("which-key").setup({})
EOF
" show all leader-key shortcuts on demand
nnoremap <leader>? :WhichKey<CR>

" ── diffview.nvim (side-by-side diffs) ──────────────────────────────────────
" \gd = open diff view of working tree, \gh = file history, \gc = close
nnoremap <leader>gd :DiffviewOpen<CR>
nnoremap <leader>gh :DiffviewFileHistory %<CR>
nnoremap <leader>gc :DiffviewClose<CR>

" ── claudecode.nvim (Claude Code inside Neovim) ─────────────────────────────
lua << EOF
require("claudecode").setup({})
EOF
" \ac = toggle Claude, \af = focus Claude, \ab = add current buffer as context
" \as (visual) = send selection to Claude, \aa/\ad = accept/deny a diff
nnoremap <leader>ac :ClaudeCode<CR>
nnoremap <leader>af :ClaudeCodeFocus<CR>
nnoremap <leader>ab :ClaudeCodeAdd %<CR>
vnoremap <leader>as :ClaudeCodeSend<CR>
nnoremap <leader>aa :ClaudeCodeDiffAccept<CR>
nnoremap <leader>ad :ClaudeCodeDiffDeny<CR>
