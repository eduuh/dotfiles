#!/bin/bash

fonts_list=(
  font-agave-nerd-font
  font-fira-mono-nerd-font
  font-caskaydia-cove-nerd-font
  font-hack-nerd-font
  font-hurmit-nerd-font
  font-ubuntu-nerd-font
)

brew tap homebrew/cask-fonts

for font in "${fonts_list[@]}"
do
  brew install --cask "$font"
done
exit
