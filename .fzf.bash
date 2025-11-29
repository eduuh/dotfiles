# Setup fzf
# ---------
if [[ ! "$PATH" == */home/edd/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/edd/.fzf/bin"
fi

eval "$(fzf --bash)"
