# Setup fzf
# ---------
if [[ ! "$PATH" == */home/edd/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/edd/.fzf/bin"
fi

source <(fzf --zsh)
