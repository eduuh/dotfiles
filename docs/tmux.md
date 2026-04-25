# Tmux Keybindings

Prefix: **`C-Space`** (Ctrl+Space)

The workflow: one **session per repo**, one **window per worktree**. Sessions are named after the bare repo (e.g. `tracker`, `kube-homelab`); windows are named after the branch (e.g. `feat-auth`). Plain clones like `dotfiles` get a single `main` window.

## Sessions

| Key | Action |
|-----|--------|
| `C-o` | Project picker (fzf over `~/projects`). Creates or switches session. |
| `t` | Kill current session, switch to next. |
| `.` | Rename current session. |
| `d` | Detach client (built-in). |

## Worktrees (as windows)

| Key | Action |
|-----|--------|
| `o` | **Go to or create worktree.** fzf list of existing worktrees. Select one → opens as window. Type a new name + Enter → creates worktree from latest `main`, opens as window. |
| `X` | Remove current window's worktree + kill the window. Refuses `main`/`master`. Prompts for `--force` if dirty. |

In a non-bare session (e.g. `dotfiles`), `o` just opens/selects a `main` window at the repo path.

## Windows

| Key | Action |
|-----|--------|
| `w` | New window (same cwd). |
| `r` | Rename window. |
| `1`–`5` | Jump to window 1–5. |
| `[` / `]` | Previous / next window. |
| `<` / `>` | Swap window left / right. |

## Panes

| Key | Action |
|-----|--------|
| `v` | Split right (vertical divider). |
| `s` | Split below (horizontal divider). |
| `←` `↓` `↑` `→` | Navigate between panes. |
| `S-←` `S-↓` `S-↑` `S-→` | Resize current pane by 5 cells. |
| `z` | Toggle zoom (fullscreen current pane). |
| `q` | Kill pane (with confirm). |

## Popups

| Key | Action |
|-----|--------|
| `e` | Toggle floating nvim scoped to the current worktree. Only one nvim ever exists: opening from a different worktree kills the previous nvim and spawns a fresh one there. Press again from inside to detach — popup closes, nvim stays alive until the next worktree switch. `:qa` quits it immediately. |
| `n` | Branch note popup (`note.md` for current git context). |
| `g` | Lazygit popup. `q` closes. |

## Copy Mode (vi)

Enter with **`C-Space Space`**.

| Key | Action |
|-----|--------|
| `v` | Start selection. |
| `C-v` | Toggle rectangle selection. |
| `y` | Copy to system clipboard + exit. |
| `/` `?` | Search forward / backward. |
| `n` `N` | Next / previous search match. |
| `g` `G` | Jump to top / bottom. |
| `C-u` `C-d` | Half-page up / down. |
| `q` or `Esc` | Exit copy mode. |

Outside copy mode: `p` paste-buffer, `P` choose-buffer.

## Config

| Key | Action |
|-----|--------|
| `R` | Reload `~/.tmux.conf`. |

---

# Nvim Keybindings

Leader: **`<Space>`**

Only the project-specific keys worth memorising — see `~/.config/nvim/lua/plugins/*.lua` for the full picture.

## Files & navigation

| Key | Action |
|-----|--------|
| `C-p` | Files (fzf-lua). |
| `<leader>ff` | Files (fzf-lua). |
| `<leader>fw` | Live grep. |
| `<leader>fo` | Old files / recent. |
| `<leader>fr` | Registers. |
| `<BS>` | Alternate buffer (`<C-^>`). |
| `C-s` | Save file. |

## Branch notes

| Key | Action |
|-----|--------|
| `<leader>nn` | Open `note.md` for current branch (or jump back via alternate buffer if already on it). |

## Quickfix

| Key | Action |
|-----|--------|
| `;n` / `;p` | Next / previous quickfix item. |
| `<leader>ql` | Quickfix list (fzf). |

## LSP (when an LSP is attached)

| Key | Action |
|-----|--------|
| `<leader>rn` | Rename symbol. |
| `<leader>ca` | Code actions. |
| `<leader>gd` | Document diagnostics. |
| `<leader>gw` | Workspace diagnostics. |
| `<leader>wd` | Workspace diagnostics (alt). |
| `<leader>ws` | Workspace symbols. |
| `<leader>lr` | Restart LSP. |

## Git / Diffview

| Key | Action |
|-----|--------|
| `<leader>gc` | Git commits (fzf). |
| `<leader>gb` | Git branches (fzf). |
| `<leader>gs` | Git stash (fzf). |
| `<leader>gp` | Gitsigns preview hunk. |
| `<leader>gr` | Gitsigns reset hunk. |
| `<leader>vd` | Diffview open. |
| `<leader>vb` | Diffview branch history. |

## Trouble

| Key | Action |
|-----|--------|
| `<leader>xx` | Workspace diagnostics. |
| `<leader>xd` | Document diagnostics. |
| `<leader>xs` | Symbols. |
| `<leader>xq` | Quickfix. |
| `<leader>xl` | Loclist. |

## Bufferline

| Key | Action |
|-----|--------|
| `<leader>bp` | Pin buffer. |
| `<leader>bo` | Close other buffers. |

## UI

| Key | Action |
|-----|--------|
| `<leader>uu` | Toggle undotree. |

## Terminal

| Key | Action |
|-----|--------|
| `C-n` | Toggle floating terminal (toggleterm). |
| `Esc Esc` | Exit terminal-insert mode. |
| `<leader>tu` | Unlock outer tmux prefix (from inside a terminal). |
| `<leader>cy` | Claude Code (yolo — skips permission prompts). |

---

# `bn` (Branch Notes CLI)

`bn` lives at `~/.bin/bn`. Every git branch gets a note at `~/projects/worktree/personal-notes/branch-notes/branch-notes/<repo>/<branch>/note.md`. Managed through the CLI — not bound to tmux directly but the primary interface for session context.

## Core

| Command | Action |
|---------|--------|
| `bn` | Ensure note exists, print dir path. |
| `bn --cat` / `-c` | Print full note contents. |
| `bn brief` | Lean SessionStart view: goal, blockers, open todos (cap 10), last 3 Progress, last 3 Decisions. |
| `bn --json` | Dump `note.yaml` as JSON for scripts / Claude skills. |
| `bn --edit` / `-e` | Open note in `$EDITOR`. |
| `bn --path` / `-p` | Print note dir path (no create). |

## Add to sections

| Command | Action |
|---------|--------|
| `bn add todo "text"` | Add todo. |
| `bn add blocker "text"` | Add blocker. |
| `bn add decision "text"` | Record a decision. |
| `bn add research "text"` | Add research item. |
| `bn add collab "text"` | Collaboration note. |
| `bn add ask "text"` | Question for user/team. |

## Lifecycle

| Command | Action |
|---------|--------|
| `bn done <id>` | Mark a todo done by stable id (e.g., `bn done t3`). |
| `bn done "text"` | Fall back to substring match — fails on ambiguity. |
| `bn log-progress "text"` | Append timestamped line to Progress (used by SessionEnd hook). |
| `bn plan list` | List Claude plan files captured for the current branch. |
| `bn plan save [src]` | Manually capture a plan (default: newest in `~/.claude/plans/`). |
| `bn plan open <slug>` | Open a captured plan in `$EDITOR` (prefix match). |
| `bn plan cat <slug>` | Print a captured plan to stdout. |
| `bn plan rm <slug>` | Remove a captured plan (asks confirmation). |
| `bn close` | Close current branch's note. |
| `bn reopen` | Reopen a closed note. |
| `bn prune` | Close notes whose worktrees are gone. |
| `bn reset` | Remove non-main worktrees + close notes. |
| `bn archive` | Archive old closed notes. |
| `bn migrate [--dry-run]` | Convert legacy md-only notes to split md + yaml. |

## Views

| Command | Action |
|---------|--------|
| `bn summary` / `s` | Dashboard: open todos + blockers across branches. |
| `bn status` / `st` | One-line status for current branch. |
| `bn todo` / `t` | Open todos across all branches. |
| `bn list` / `l` | Active notes (`--all` for closed too). |
| `bn worktrees` / `w` | All active worktrees with detail. |
| `bn search <text>` | Search across all notes. |
| `bn stale [--days N]` | Notes with no recent activity. |

## Build / refresh

| Command | Action |
|---------|--------|
| `bn build` / `b [name]` | Run a repo-scoped script (default: `build`). |
| `bn refresh` / `rf` | Fetch, pull, build current branch. |
| `bn refresh-all` / `ra` | Refresh all main worktrees. |
| `bn script new <name>` | Create a repo script. |

## Links

| Command | Action |
|---------|--------|
| `bn pr [url]` | Link or open PR for current branch. |
| `bn link <id>` | Link or open work item. |
| `bn files` / `f` | Investigation file management. |

---

# The workflow in one page

1. **Start a session** — `C-Space C-o` → pick a repo. `tat` creates or switches.
2. **Branch off main** — `C-Space o`, type `feat/foo`. `tmux-wt.sh` fetches, creates worktree from latest main, opens as window named `feat-foo`.
3. **Work** — `C-Space e` for nvim, `C-Space g` for lazygit, `C-Space n` for the branch note. Inside nvim use `<Space>nn` to jump to the note.
4. **Context-switch** — `C-Space [` / `]` between worktree windows in the same session. `C-Space C-o` to switch to a different repo.
5. **Done with a branch** — `C-Space X`, confirm, worktree is removed and window closed.
6. **Done for the day** — `C-Space t` kills the session and moves to the next.
