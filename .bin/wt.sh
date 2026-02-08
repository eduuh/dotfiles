#!/usr/bin/env zsh
# wt.sh - Git worktree manager for bare repo workflow
# Bare repos: ~/projects/reponame.git
# Worktrees: ~/projects/reponame-branchname

set -e

PROJECT_ROOT="$HOME/projects"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repositories that should NOT be cloned as bare (regular clone instead)
# These repos will be cloned to ~/projects/reponame (without .git suffix)
REGULAR_CLONE_REPOS=(
    "dotfiles"
    "nvim"
    "personal-notes"
)

usage() {
    cat << EOF
Usage: wt <command> [args]

Commands:
  clone <url>              Clone repo (bare by default, some repos as regular)
  add [branch]             Add worktree (interactive if no branch specified)
  list                     List all worktrees for current repo
  remove [worktree]        Remove worktree (interactive if not specified)
  go [worktree]            cd to worktree (interactive if not specified)
  fetch                    Fetch all remotes for bare repo
  prune                    Prune stale worktree references

Examples:
  wt clone git@github.com:user/test.git    # Creates ~/projects/test.git
  wt add main                              # Creates ~/projects/test-main
  wt add user/feature-x                    # Creates ~/projects/test-user-feature-x
  wt add -b new-feature main               # Create new branch from main
EOF
}

# Sanitize branch name for directory (replace / with -)
sanitize_branch() {
    echo "$1" | tr '/' '-'
}

# Check if repo should be cloned as regular (not bare)
is_regular_clone() {
    local repo_name="$1"
    for pattern in "${REGULAR_CLONE_REPOS[@]}"; do
        [[ "$repo_name" == "$pattern" ]] && return 0
    done
    return 1
}

# Get repo name from bare repo path or current worktree
get_repo_name() {
    local dir="$1"
    if [[ "$dir" == *.git ]]; then
        basename "$dir" .git
    elif [[ -f "$dir/.git" ]]; then
        # We're in a worktree, read the gitdir
        local gitdir=$(cat "$dir/.git" | sed 's/gitdir: //')
        basename "$(dirname "$(dirname "$gitdir")")" .git
    elif [[ -d "$dir/.git" ]]; then
        # Regular repo
        basename "$dir"
    else
        return 1
    fi
}

# Find bare repo from current location
find_bare_repo() {
    local cwd="${1:-$(pwd)}"

    # If we're in a bare repo
    if [[ -d "$cwd/worktrees" && -f "$cwd/HEAD" ]]; then
        echo "$cwd"
        return 0
    fi

    # If we're in a worktree
    if [[ -f "$cwd/.git" ]]; then
        local gitdir=$(cat "$cwd/.git" | sed 's/gitdir: //')
        # gitdir points to .bare/worktrees/<name>
        local bare_path=$(dirname "$(dirname "$gitdir")")
        if [[ -d "$bare_path" ]]; then
            echo "$(dirname "$bare_path")"
            return 0
        fi
    fi

    # Check if there's a .bare directory (new style)
    if [[ -d "$cwd/.bare" ]]; then
        echo "$cwd"
        return 0
    fi

    return 1
}

# Clone a repo (bare by default, some repos as regular)
cmd_clone() {
    local url="$1"
    [[ -z "$url" ]] && { echo -e "${RED}Error: URL required${NC}"; usage; exit 1; }

    # Extract repo name from URL
    local repo_name=$(basename "$url" .git)

    # Check if this repo should be cloned as regular (not bare)
    if is_regular_clone "$repo_name"; then
        local clone_path="$PROJECT_ROOT/${repo_name}"

        if [[ -d "$clone_path" ]]; then
            echo -e "${RED}Error: $clone_path already exists${NC}"
            exit 1
        fi

        echo -e "${BLUE}Cloning $url as regular repo (not bare)...${NC}"
        git clone "$url" "$clone_path"

        echo -e "${GREEN}✓ Cloned to $clone_path${NC}"
        echo -e "${YELLOW}This is a regular repo (not bare). Use standard git commands.${NC}"
    else
        local bare_path="$PROJECT_ROOT/${repo_name}.git"

        if [[ -d "$bare_path" ]]; then
            echo -e "${RED}Error: $bare_path already exists${NC}"
            exit 1
        fi

        echo -e "${BLUE}Cloning $url as bare repo...${NC}"
        git clone --bare "$url" "$bare_path"

        # Set up fetch to get all branches
        cd "$bare_path"
        git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
        git fetch origin

        echo -e "${GREEN}✓ Cloned to $bare_path${NC}"
        echo -e "${YELLOW}Next: cd $bare_path && wt add main${NC}"
    fi
}

# Add a worktree
cmd_add() {
    local bare_repo=$(find_bare_repo)

    # If not in a repo context, let user select from bare repos
    if [[ -z "$bare_repo" ]]; then
        local bare_repos=("$PROJECT_ROOT"/*.git(N/))
        if [[ ${#bare_repos[@]} -eq 0 ]]; then
            echo -e "${RED}Error: No bare repos found in $PROJECT_ROOT${NC}"
            exit 1
        fi

        echo -e "${BLUE}Select bare repo:${NC}"
        bare_repo=$(printf '%s\n' "${bare_repos[@]}" | fzf --reverse)
        [[ -z "$bare_repo" ]] && exit 0
    fi

    local repo_name=$(get_repo_name "$bare_repo")
    local git_dir="$bare_repo"
    [[ -d "$bare_repo/.bare" ]] && git_dir="$bare_repo/.bare"

    local branch="$1"
    local create_new=false
    local base_branch=""

    # Handle -b flag for new branch
    if [[ "$branch" == "-b" ]]; then
        create_new=true
        branch="$2"
        base_branch="$3"
    fi

    # Interactive branch selection if not specified
    if [[ -z "$branch" ]]; then
        echo -e "${BLUE}Select branch to checkout:${NC}"
        branch=$(git --git-dir="$git_dir" branch -a --format='%(refname:short)' | \
            sed 's|^origin/||' | sort -u | grep -v '^HEAD$' | \
            fzf --reverse --header="Select branch")
        [[ -z "$branch" ]] && exit 0
    fi

    local sanitized=$(sanitize_branch "$branch")
    local worktree_path="$PROJECT_ROOT/${repo_name}-${sanitized}"

    if [[ -d "$worktree_path" ]]; then
        echo -e "${YELLOW}Worktree already exists: $worktree_path${NC}"
        echo -e "Use: cd $worktree_path"
        exit 0
    fi

    echo -e "${BLUE}Creating worktree: $worktree_path${NC}"

    if $create_new; then
        [[ -z "$base_branch" ]] && base_branch="main"
        git --git-dir="$git_dir" worktree add -b "$branch" "$worktree_path" "$base_branch"
    else
        # Check if branch exists locally or remotely
        if git --git-dir="$git_dir" show-ref --verify --quiet "refs/heads/$branch"; then
            git --git-dir="$git_dir" worktree add "$worktree_path" "$branch"
        elif git --git-dir="$git_dir" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
            git --git-dir="$git_dir" worktree add "$worktree_path" "$branch"
        else
            echo -e "${YELLOW}Branch '$branch' not found. Creating new branch...${NC}"
            git --git-dir="$git_dir" worktree add -b "$branch" "$worktree_path" "main"
        fi
    fi

    echo -e "${GREEN}✓ Created worktree: $worktree_path${NC}"
    echo -e "cd $worktree_path"
}

# List worktrees
cmd_list() {
    local bare_repo=$(find_bare_repo)

    if [[ -z "$bare_repo" ]]; then
        # List all worktrees for all bare repos
        echo -e "${BLUE}All worktrees:${NC}"
        for bare in "$PROJECT_ROOT"/*.git(N/); do
            local name=$(basename "$bare" .git)
            echo -e "\n${YELLOW}$name:${NC}"
            local git_dir="$bare"
            [[ -d "$bare/.bare" ]] && git_dir="$bare/.bare"
            git --git-dir="$git_dir" worktree list
        done
    else
        local git_dir="$bare_repo"
        [[ -d "$bare_repo/.bare" ]] && git_dir="$bare_repo/.bare"
        git --git-dir="$git_dir" worktree list
    fi
}

# Remove a worktree
cmd_remove() {
    local worktree="$1"
    local bare_repo=$(find_bare_repo)

    if [[ -z "$worktree" ]]; then
        # Interactive selection
        local worktrees=()

        if [[ -n "$bare_repo" ]]; then
            local git_dir="$bare_repo"
            [[ -d "$bare_repo/.bare" ]] && git_dir="$bare_repo/.bare"
            worktrees=($(git --git-dir="$git_dir" worktree list --porcelain | grep '^worktree' | cut -d' ' -f2))
        else
            # Gather from all bare repos
            for bare in "$PROJECT_ROOT"/*.git(N/); do
                local git_dir="$bare"
                [[ -d "$bare/.bare" ]] && git_dir="$bare/.bare"
                worktrees+=($(git --git-dir="$git_dir" worktree list --porcelain | grep '^worktree' | cut -d' ' -f2))
            done
        fi

        [[ ${#worktrees[@]} -eq 0 ]] && { echo -e "${YELLOW}No worktrees found${NC}"; exit 0; }

        echo -e "${BLUE}Select worktree to remove:${NC}"
        worktree=$(printf '%s\n' "${worktrees[@]}" | fzf --reverse)
        [[ -z "$worktree" ]] && exit 0
    fi

    # Expand to full path if needed
    [[ "$worktree" != /* ]] && worktree="$PROJECT_ROOT/$worktree"

    if [[ ! -d "$worktree" ]]; then
        echo -e "${RED}Error: Worktree not found: $worktree${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Removing worktree: $worktree${NC}"

    # Find the bare repo for this worktree
    local wt_bare=$(find_bare_repo "$worktree")
    if [[ -z "$wt_bare" ]]; then
        echo -e "${RED}Error: Could not find bare repo for worktree${NC}"
        exit 1
    fi

    local git_dir="$wt_bare"
    [[ -d "$wt_bare/.bare" ]] && git_dir="$wt_bare/.bare"

    git --git-dir="$git_dir" worktree remove "$worktree"
    echo -e "${GREEN}✓ Removed worktree${NC}"
}

# Go to a worktree (for shell functions)
cmd_go() {
    local worktree="$1"

    if [[ -z "$worktree" ]]; then
        # Interactive selection from all worktrees in PROJECT_ROOT
        local worktrees=()
        for dir in "$PROJECT_ROOT"/*(N/); do
            local name=$(basename "$dir")
            [[ "$name" == *.git ]] && continue
            [[ "$name" == .* ]] && continue
            # Check if it's a worktree (has .git file, not directory)
            [[ -f "$dir/.git" ]] && worktrees+=("$name")
        done

        [[ ${#worktrees[@]} -eq 0 ]] && { echo -e "${YELLOW}No worktrees found${NC}"; exit 0; }

        worktree=$(printf '%s\n' "${worktrees[@]}" | fzf --reverse --header="Select worktree")
        [[ -z "$worktree" ]] && exit 0
    fi

    local path="$PROJECT_ROOT/$worktree"
    [[ ! -d "$path" ]] && { echo -e "${RED}Error: $path not found${NC}"; exit 1; }

    # Output path for shell wrapper to cd
    echo "$path"
}

# Fetch all remotes
cmd_fetch() {
    local bare_repo=$(find_bare_repo)
    [[ -z "$bare_repo" ]] && { echo -e "${RED}Error: Not in a worktree context${NC}"; exit 1; }

    local git_dir="$bare_repo"
    [[ -d "$bare_repo/.bare" ]] && git_dir="$bare_repo/.bare"

    echo -e "${BLUE}Fetching all remotes...${NC}"
    git --git-dir="$git_dir" fetch --all --prune
    echo -e "${GREEN}✓ Fetch complete${NC}"
}

# Prune stale worktree references
cmd_prune() {
    local bare_repo=$(find_bare_repo)

    if [[ -z "$bare_repo" ]]; then
        echo -e "${BLUE}Pruning all bare repos...${NC}"
        for bare in "$PROJECT_ROOT"/*.git(N/); do
            local git_dir="$bare"
            [[ -d "$bare/.bare" ]] && git_dir="$bare/.bare"
            git --git-dir="$git_dir" worktree prune
        done
    else
        local git_dir="$bare_repo"
        [[ -d "$bare_repo/.bare" ]] && git_dir="$bare_repo/.bare"
        git --git-dir="$git_dir" worktree prune
    fi

    echo -e "${GREEN}✓ Pruned stale worktree references${NC}"
}

# Main
case "${1:-}" in
    clone)  shift; cmd_clone "$@" ;;
    add)    shift; cmd_add "$@" ;;
    list|ls) cmd_list ;;
    remove|rm) shift; cmd_remove "$@" ;;
    go)     shift; cmd_go "$@" ;;
    fetch)  cmd_fetch ;;
    prune)  cmd_prune ;;
    -h|--help|help|"") usage ;;
    *)      echo -e "${RED}Unknown command: $1${NC}"; usage; exit 1 ;;
esac
