#!/bin/bash

echo "Enter the commit message: "
read $message
cd $HOME/windows/drive_1/dotfiles/
git add .
git commit -m "$message" 
git push -u origin main
dunstify "updated dotfiles"
