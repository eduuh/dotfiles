#!/bin/bash

# Get the Git branch for the current pane's directory
git_branch() {
  git -C "$1" symbolic-ref --short HEAD 2>/dev/null ||
    git -C "$1" rev-parse --short HEAD 2>/dev/null ||
    echo ""
}

pane_path="$1"
branch=$(git_branch "$pane_path")
if [ -n "$branch" ]; then
  echo " $branch"
else
  echo ""
fi
