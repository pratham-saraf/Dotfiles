#!/bin/zsh

cd ~

mv .zhistory .zsh_history_bad

strings .zsh_history_bad > .zhistory

fc -R .zhistory

rm ~/.zsh_history_bad

