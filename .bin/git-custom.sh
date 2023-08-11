#!/bin/bash
current_dir=$(pwd)

root_dir="$HOME"

if [ "$current_dir" == "$root_dir" ]; then
  git --git-dir="$HOME/.cfg" --work-tree="$root_dir" "$@"
else
  git "$@"
fi
