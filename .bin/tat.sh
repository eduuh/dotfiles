#!/usr/bin/env zsh
# tat.sh - Tmux session manager for projects across multiple locations
# Usage: Run inside tmux to select and switch to a project

# Define project locations with aliases
declare -A project_paths=(
  ["wsl"]="$HOME/projects"
  ["win"]="/mnt/c/Users/edwinmuraya/projects"
)

# Require tmux session
if [[ -z "$TMUX" ]]; then
  echo "Error: This script must be run inside a tmux session."
  exit 1
fi

# Get active sessions and initialize directories list
active_sessions=$(tmux list-sessions -F "tmux:#S" 2>/dev/null || echo "")
directories=""

# Get directories from all configured paths
for key in "${(@k)project_paths}"; do
  dir_path="${project_paths[$key]}"
  if [[ -d "$dir_path" ]]; then
    # Get top-level directories excluding system ones
    dir_list=$(cd "$dir_path" && find . -maxdepth 1 -type d \
      -not -path "." \
      -not -path "./.git" \
      -not -path "./node_modules" \
      -not -path "./.vscode" \
      -not -path "./.idea" \
      -not -path "./__pycache__" \
      | sed 's|^\./||g' | sort)
      
    # Add prefix to directories except for number-only project names
    if [[ -n "$dir_list" ]]; then
      while IFS= read -r line; do
        if [[ "$line" =~ ^[0-9]+$ ]]; then
          # Number-only project name, keep as is
          if [[ -n "$directories" ]]; then
            directories="$directories"$'\n'"$line"
          else
            directories="$line"
          fi
        else
          # Normal project name, add prefix with underscore delimiter
          if [[ -n "$directories" ]]; then
            directories="$directories"$'\n'"$key"_"$line"
          else
            directories="$key"_"$line"
          fi
        fi
      done <<< "$dir_list"
    fi
  fi
done

# Include all defined projects in the list
all_project_paths=""
for key in "${(@k)project_paths}"; do
  project_path="${project_paths[$key]}"
  if [[ -d "$project_path" ]]; then
    if [[ -n "$all_project_paths" ]]; then
      all_project_paths="$all_project_paths"$'\n'"path_$key:$project_path"
    else
      all_project_paths="path_$key:$project_path"
    fi
  fi
done

combined_list=$(echo -e "$directories\n$active_sessions\n$all_project_paths" | grep -v '^$' | sort -u)

fzf_cmd=$(command -v fzf || echo "~/.fzf/bin/fzf")

# Check if fzf is available
if [[ ! -x "$fzf_cmd" ]]; then
  echo "Error: fzf not found. Please install fzf to use this script."
  exit 1
fi

selected=$(echo "$combined_list" | $fzf_cmd --reverse --header="Select project/session/path >")

# If nothing selected, exit
if [[ -z "$selected" ]]; then
  echo "No selection made. Exiting."
  exit 1
fi

# Parse selection to get real session name and path
if [[ $selected == tmux:* ]]; then
  # Selected a tmux session
  session_name=${selected#tmux:}
  if tmux has-session -t "=$session_name" 2>/dev/null; then
    path_name=$(tmux display-message -p -t "$session_name" '#{pane_current_path}' 2>/dev/null || echo "$HOME")
  else
    path_name="$HOME"
  fi
elif [[ $selected == path_* ]]; then
  # Selected a project path directly
  prefix_name=${selected#path_}
  prefix_name=${prefix_name%%:*}
  path_name=${selected#path_$prefix_name:}
  session_name=$prefix_name
else
  # Selected a directory with prefix
  if [[ $selected =~ ^[0-9]+$ ]]; then
    # Number-only project name, no prefix
    dir_name=$selected
    path_name="$HOME/$dir_name"
    session_name=$dir_name
  else
    # Regular case with prefix - now using underscore delimiter
    prefix_name=${selected%%_*}
    dir_name=${selected#*_}
    session_name=$selected
    
    # Set the correct path based on the prefix
    for key in "${(@k)project_paths}"; do
      if [[ "$prefix_name" == "$key" ]]; then
        path_name="${project_paths[$key]}/$dir_name"
        break
      fi
    done
    
    # Fallback if prefix not found in our paths
    if [[ -z "$path_name" ]]; then
      path_name="$HOME/$dir_name"
    fi
  fi
fi

echo "Session name is \"$session_name\""
echo "Path name is \"$path_name\""

if [[ -z "$session_name" ]]; then
  exit 1
fi

# Only create a new session if it doesn't exist
if ! tmux has-session -t "=$session_name" 2>/dev/null; then
  echo "Creating new session: $session_name"
  tmux new-session -d -s "$session_name" -c "$path_name"
fi

# Switch to the session
tmux switch-client -t "$session_name"
