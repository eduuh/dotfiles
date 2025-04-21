# Setup fzf
# ---------
if [[ ! "$PATH" == */home/eduuh/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/eduuh/.fzf/bin"
fi

eval "$(fzf --bash)"
