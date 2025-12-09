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

# Initialize directories and project sessions lists
directories=""
project_sessions=()  # Array to track project session names

# Initialize associative array to track project sources
typeset -A project_sources

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
      | sed 's|^\./||g')
      
    if [[ -n "$dir_list" ]]; then
      while IFS= read -r line; do
        if [[ -n "${project_sources[$line]}" ]]; then
          project_sources[$line]="${project_sources[$line]} $key"
        else
          project_sources[$line]="$key"
        fi
      done <<< "$dir_list"
    fi
  fi
done

# Build directories list and project sessions
for name in "${(@k)project_sources}"; do
  # Split sources into array
  sources=(${=project_sources[$name]})
  
  if [[ ${#sources[@]} -gt 1 ]]; then
    # Duplicates exist, add prefix for all
    for key in "${sources[@]}"; do
      entry="${key}_${name}"
      if [[ -n "$directories" ]]; then
        directories="$directories"$'\n'"$entry"
      else
        directories="$entry"
      fi
      project_sessions+=("$entry")
    done
  else
    # Unique, no prefix
    entry="$name"
    if [[ -n "$directories" ]]; then
      directories="$directories"$'\n'"$entry"
    else
      directories="$entry"
    fi
    project_sessions+=("$entry")
  fi
done

# Sort directories for display
directories=$(echo "$directories" | sort)

# Get active tmux sessions
active_sessions=$(tmux list-sessions -F "#S" 2>/dev/null || echo "")
filtered_sessions=""

# Filter out tmux sessions that match project directories or path keys
if [[ -n "$active_sessions" ]]; then
  while IFS= read -r session; do
    # Check if this session is already in our project list
    session_in_projects=0
    for project in "${project_sessions[@]}"; do
      if [[ "$session" == "$project" ]]; then
        session_in_projects=1
        break
      fi
    done

    # Also check if this session name matches one of our path keys (wsl, win)
    if [[ $session_in_projects -eq 0 && " ${(k)project_paths[@]} " == *" $session "* ]]; then
      session_in_projects=1
    fi

    # Only add sessions that aren't already represented by a project directory or path key
    if [[ $session_in_projects -eq 0 ]]; then
      # Get the session's current path
      session_path=$(tmux display-message -p -t "$session" '#{pane_current_path}' 2>/dev/null || echo "$HOME")
      
      if [[ -n "$filtered_sessions" ]]; then
        filtered_sessions="$filtered_sessions"$'\n'"path:$session:$session_path"
      else
        filtered_sessions="path:$session:$session_path"
      fi
    fi
  done <<< "$active_sessions"
fi
# Initialize filtered paths variable
all_project_paths=""
filtered_paths=""

# Process project paths and prepare for deduplication
for key in "${(@k)project_paths}"; do
  project_path="${project_paths[$key]}"
  if [[ -d "$project_path" ]]; then
    if [[ -n "$all_project_paths" ]]; then
      all_project_paths="$all_project_paths"$'\n'"path $key:$project_path"
    else
      all_project_paths="path $key:$project_path"
    fi
  fi
done

# Filter out path entries that are already represented by project directories
if [[ -n "$all_project_paths" ]]; then
  # We always include all paths regardless of active sessions
  # This ensures both WSL and Windows paths are always visible
  filtered_paths="$all_project_paths"
fi

# Combine deduplicated lists (project directories, non-duplicate tmux sessions with path: prefix, and non-duplicate paths)
combined_list=$(echo -e "$directories\n$filtered_sessions\n$filtered_paths" | grep -v '^$' | sort -u)

fzf_cmd=$(command -v fzf || echo "$HOME/.fzf/bin/fzf")

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
if [[ $selected == path:* ]]; then
  # Selected a tmux session
  # Format is path:NAME:PATH
  session_name="${selected#path:}"
  session_name="${session_name%%:*}"
  path_name="${selected#path:$session_name:}"
elif [[ $selected == path\ * ]]; then
  # Selected a project path directly (path KEY:PATH)
  # Format is "path key:path_value"
  prefix_name=${selected#path }
  prefix_name=${prefix_name%%:*}
  path_name=${selected#path $prefix_name:}
  session_name=$prefix_name
else
  # Selected a directory (prefixed or unique)
  session_name=$selected
  path_name=""
  
  # 1. Try to parse as prefixed path
  for key in "${(@k)project_paths}"; do
    if [[ "$selected" == "${key}_"* ]]; then
      # Potential prefix match
      potential_dir="${selected#${key}_}"
      potential_path="${project_paths[$key]}/$potential_dir"
      
      if [[ -d "$potential_path" ]]; then
        path_name="$potential_path"
        break
      fi
    fi
  done
  
  # 2. If not found as prefixed, try as exact name in any path
  if [[ -z "$path_name" ]]; then
    for key in "${(@k)project_paths}"; do
      potential_path="${project_paths[$key]}/$selected"
      if [[ -d "$potential_path" ]]; then
        path_name="$potential_path"
        break
      fi
    done
  fi
  
  # 3. Fallback
  if [[ -z "$path_name" ]]; then
     # Default to first configured path
     for key in "${(@k)project_paths}"; do
        path_name="${project_paths[$key]}/$selected"
        break
     done
  fi
fi

echo "Session name is \"$session_name\""
echo "Path name is \"$path_name\""

if [[ -z "$session_name" ]]; then
  echo "Error: Empty session name"
  exit 1
fi

# Only create a new session if it doesn't exist
if ! tmux has-session -t "=$session_name" 2>/dev/null; then
  echo "Creating new session: $session_name"
  tmux new-session -d -s "$session_name" -c "$path_name"
fi

# Switch to the session
tmux switch-client -t "$session_name"
