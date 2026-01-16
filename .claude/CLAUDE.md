# Global Claude Instructions

## About Me
- Name: Edwin (edd)
- Primary editor: Neovim
- Shell: zsh
- OS: macOS (Darwin)
- Projects directory: ~/projects

## Preferences

### Code Style
- Prefer functional programming patterns where appropriate
- Use TypeScript for JS projects (strict mode)
- Keep code concise and avoid over-engineering
- No emojis in code or commit messages unless asked

### Git
- Commit messages: Use conventional commits (feat:, fix:, refactor:, docs:, chore:)
- Do NOT add Claude co-authorship to commits
- Always create PRs for protected branches
- Always create PRs as drafts (use `gh pr create --draft` or `az repos pr create --draft`)

### Shell Scripts
- Use zsh (#!/usr/bin/env zsh)
- Prefer portable POSIX when possible
- Quote variables properly

### Kubernetes
- Use kustomize for overlays
- Prefer declarative YAML over imperative commands

## Tech Stack
- **Frontend**: React, Next.js, TypeScript, Tailwind CSS
- **Backend**: .NET/C#, Node.js
- **Infrastructure**: Kubernetes, Docker, Talos Linux
- **Tools**: lazygit, tmux, fzf, zoxide

## Common Tasks
- When creating tmux scripts, source ~/.bin/tmux-lib.sh for shared utilities
- Use homebrew for package management on macOS
- Kubernetes configs are in ~/projects/kube

## Personal Notes

My notes are in `~/projects/personal-notes` (Obsidian vault). When working on any project and you learn something useful or solve a tricky problem, capture it.

### Adding Notes (goes to staging for my review)

```bash
# Learning entry (most common)
~/projects/personal-notes/scripts/learn.sh "Topic" "What was learned"

# Quick capture
~/projects/personal-notes/scripts/inbox.sh "Quick thought"

# New note
~/projects/personal-notes/scripts/note.sh "Title" [folder]
```

### When to Add Notes

- Discovered a useful pattern or solution
- Solved a tricky bug (document the fix)
- Learned something new about a technology
- Found useful commands or configurations

### Task Documentation

When working on a task, document approach and solutions:

```bash
# Start a task
~/projects/personal-notes/scripts/task.sh "Fix auth bug" new "Users getting logged out randomly"

# Document approach
~/projects/personal-notes/scripts/task.sh "Fix auth bug" approach "Check token refresh logic"

# Log problems
~/projects/personal-notes/scripts/task.sh "Fix auth bug" problem "Token expires during slow requests"

# Document solution
~/projects/personal-notes/scripts/task.sh "Fix auth bug" solution "Added retry with backoff"

# Record learnings
~/projects/personal-notes/scripts/task.sh "Fix auth bug" learn "Always handle refresh timeouts"
```

### Staging Workflow

All notes go to `.claude/staging/` first. I review and approve with:
```bash
~/projects/personal-notes/scripts/approve.sh --list  # see staged
~/projects/personal-notes/scripts/approve.sh --all   # approve all
```
