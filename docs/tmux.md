# Tmux Workflow

A streamlined tmux workflow with fuzzy finding, project templates, and smart navigation.

## Dependencies

Installed automatically via setup scripts:

| Package | Purpose |
|---------|---------|
| `tmux` | Terminal multiplexer |
| `fzf` | Fuzzy finder |
| `zoxide` | Smart directory jumping (frecency) |
| `bat` | Syntax-highlighted previews |
| `tree` | Directory tree display |
| `jq` | JSON parsing (package.json scripts) |
| `lazygit` | Git TUI |

## Key Bindings

Prefix is `Ctrl+Space`.

### Navigation

| Binding | Action |
|---------|--------|
| `C-Space C-o` | **Project picker** - browse ~/projects with preview |
| `C-Space C-n` | **Tmux navigator** - fuzzy search sessions/windows/panes |
| `C-Space C-s` | Session tree (built-in) |
| `C-Space g` | Lazygit popup |
| `` C-Space ` `` | Floating terminal |

### Panes

| Binding | Action |
|---------|--------|
| `C-Space v` | Split vertical (right) |
| `C-Space s` | Split horizontal (below) |
| `Arrow keys` | Navigate panes |
| `Shift+Arrows` | Resize panes |
| `C-Space z` | Toggle zoom |
| `C-Space q` | Kill pane (with confirm) |
| `C-Space S` | Swap panes |
| `C-Space J` | Join pane from another window |

### Windows

| Binding | Action |
|---------|--------|
| `C-Space w` | New window |
| `C-Space r` | Rename window |
| `C-Space 1-5` | Jump to window 1-5 |
| `C-Space [` | Previous window |
| `C-Space ]` | Next window |
| `C-Space <` | Move window left |
| `C-Space >` | Move window right |

### Sessions

| Binding | Action |
|---------|--------|
| `C-Space $` | Rename session |
| `C-Space t` | Kill session & switch to next |

### Copy Mode (vi-style)

| Binding | Action |
|---------|--------|
| `C-Space Space` | Enter copy mode |
| `v` | Begin selection |
| `C-v` | Rectangle selection |
| `y` | Copy to system clipboard |
| `/` | Search forward |
| `?` | Search backward |
| `C-Space p` | Paste |
| `C-Space P` | Choose buffer |

### Special

| Binding | Action |
|---------|--------|
| `C-Space R` | Reload config |
| `C-Space k` | Toggle keys-off mode (for nested tmux) |

## Scripts

### Project Picker (`C-Space C-o`)

```
~/.bin/tmux/tat
```

- Lists all directories in `~/projects`
- Sorted by **zoxide frecency** (most used first)
- Shows `[*]` indicator for active sessions
- Preview pane shows: git status, project type, README

### Tmux Navigator (`C-Space C-n`)

```
~/.bin/tmux/tmux-nav.sh
```

Unified fuzzy finder for all tmux objects. Use symbol prefixes to filter:

| Prefix | Shows |
|--------|-------|
| `@` | Sessions only |
| `#` | Windows only |
| `:` | Panes only |
| (none) | Everything |

Example: Type `@work` to filter sessions containing "work".

### Session Templates

```
~/.bin/tmux/tat-template.sh
```

Auto-detects project type and creates appropriate layout:

| Detected By | Template | Windows |
|-------------|----------|---------|
| `package.json` | Node.js | editor+shell, server, git |
| `Cargo.toml` | Rust | editor+shell, git |
| `go.mod` | Go | editor+shell, git |
| `pyproject.toml` | Python | editor+shell (venv), git |
| `cluster/` + `Makefile` | Kubernetes | editor, k9s, git |
| (default) | Simple | single pane |

Override with `.tmux-template` file in project root containing template name.

## Configuration Files

| File | Purpose |
|------|---------|
| `~/.tmux.conf` | Main tmux configuration |
| `~/.bin/tmux/tat` | Project picker script |
| `~/.bin/tmux/tat-preview.sh` | fzf preview for projects |
| `~/.bin/tmux/tat-template.sh` | Session template logic |
| `~/.bin/tmux/tmux-nav.sh` | Unified tmux navigator |

## Plugins

Managed via [TPM](https://github.com/tmux-plugins/tpm):

- **tmux-resurrect** - Save/restore sessions across restarts
- **tmux-continuum** - Auto-save every 15 minutes, auto-restore on start

Install plugins after setup:

```bash
# Inside tmux
C-Space I
```
