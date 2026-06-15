# branch-notes-maestro

Keep execution maps (branch notes) continuously updated as work progresses.

## What this skill does

Teaches AI agents (and humans) how to maintain Execution Maps on the Atlas server in a way that keeps them useful and current. Execution Maps are the source of truth for branch state: todos, decisions, blockers, research, scripts, and links.

The skill guides **when to update**, **what to write**, and **how to keep notes alive** throughout a coding session rather than dumping them all at the end.

## When to use

- **Before starting work** on a branch: Read the map to understand context and open items
- **During work**: Update continuously (mark todos done, log decisions, add blockers)
- **Between tasks**: Check what's blocking, what needs research, what's decided
- **At natural pause points**: After significant work completes, sync to server
- **Before handing off**: Ensure map reflects current state for others

## Core principles

### 1. Todos — One checkbox, one action

**Structure:**
```markdown
- [x] Completed task
- [ ] Next task to do
- [ ] Research question to investigate
```

**Rules:**
- One checkbox per actionable item (not per step within an action)
- Mark `[x]` **immediately** when you finish (don't batch at end of session)
- Checkbox is done = task complete, not "I started it"
- If a task gets blocked: remove from Todos, add to Blockers instead

**Example — Good:**
```markdown
- [x] Add branch note editor modal
- [x] Wire mutations to save changes
- [ ] Implement todo checkbox toggling
- [ ] Add file upload component
```

**Example — Bad:**
```markdown
- [ ] Build editor (open modal, add textarea, save button, test)
- [ ] Finish todo feature and other stuff
```

### 2. Decisions — Why we chose X

**Structure:**
```markdown
- Chose TypeScript for CLI (zero dependencies, native type-stripping)
- Using Relay for data fetching (cache layer + type safety)
- Store all state in mind maps (single source of truth)
```

**Rules:**
- Log **immediately** after deciding, not from memory later
- Include tradeoff: why X over Y, what did we give up
- Add context future-you needs: "Why did we avoid option Z?"
- Decisions are reference material, not action items
- Don't update decisions unless you change your mind (then note why)

**Example — Good:**
```markdown
- Chose React hooks over class components (simpler mental model, composable logic)
- Direct API calls instead of GraphQL for auth (one-off request, no cache needed)
- Skip permission checks in tests (integration tests run as app owner)
```

**Example — Bad:**
```markdown
- Built the editor
- Used the API
- Everything works
```

### 3. Blockers — External, not todos

**Structure:**
```markdown
Blocked on: Backend schema update from @alice (expected Friday 2026-06-19)

FalkorDB concurrency testing needed before scaling to 10k nodes
(waiting on perf test infrastructure setup, @bob's team)
```

**Rules:**
- Blocker = something **you can't fix now** (external dependency, waiting on someone, unknown)
- Blocker ≠ todo (if you can do it, it goes in todos, not blockers)
- Include: what, who (if applicable), when it will unblock
- Remove blocker the **instant** it unblocks (don't leave stale ones)
- If a blocker becomes a todo (you can now unblock yourself), move it

**Example — Good:**
```markdown
Blocked on: API team's schema changes (PR #456, reviewing)
Reason: Can't implement payment endpoint until webhook schema is finalized

Blocked on: Setting up E2E test environment
Reason: Need Docker setup on CI runner (infrastructure team ticket #789)
```

**Example — Bad:**
```markdown
Need to test the API
Can't figure out the payment thing
Tests aren't running
```

### 4. Decisions — What we discovered

**Structure:**
```markdown
- [ ] Investigate FalkorDB query performance at scale
- [ ] How does offline sync handle concurrent writes?
- [ ] Should we migrate auth to OIDC?
```

**Rules:**
- Questions you need to answer before proceeding
- Not blocking (you can work on other things)
- When you answer one: move to Decisions with the answer
- If you start investigating: note your findings in Decisions, remove from To Research

### 5. Links — External references

**Structure:**
```markdown
[GitHub PR #42: Implement atlas_read_map](https://github.com/...)
[ADO Task 11047593: Execution Map UX](https://dev.azure.com/...)
[Architecture Decision Doc](https://docs.internal/atlas/design)
[Reference: FalkorDB Query Optimization](https://falkordb.com/docs/...)
```

**Rules:**
- Link to everything relevant: PRs, tasks, docs, references
- Update links as PRs merge, tasks close, etc.
- Clickable from the web UI
- One link per line

### 6. Scripts — Executable commands

**Format:**
```bash
#!/bin/bash
# Run backend tests
cd backend && dotnet test

# Or run frontend E2E
cd frontend && npm run test:e2e
```

**Rules:**
- Real, copy-pasteable commands
- Include comments for clarity
- Store in Attachments on the repo node
- Available to all branches via inheritance

---

## Execution Map structure

```
atlas (repo root)
├── Attachments: build.sh, test.sh, dev-up.sh (shared scripts)
│
└── bn-remote (branch)
    ├── Todos — [ ] and [x] checkboxes
    ├── Decisions — why we chose X
    ├── Blockers — external dependencies
    ├── To Research — questions to investigate
    ├── Links — PRs, tasks, docs
    └── Scripts — one-off commands for this branch
```

---

## Workflow: Keep notes alive

### When starting work
1. **Read the map**: `bnr cat` or visit `/app/branch-notes` in Atlas UI
2. Understand: what's open, what's blocked, what was decided
3. Pick a todo from the list or identify new work

### During work (continuously)
1. **Mark todos done** immediately when you finish (don't batch)
   - Before switching tasks: check what's done, update map
2. **Log decisions** right after deciding (not from memory later)
   - Why X over Y? Include tradeoff
3. **Add blockers** the instant something blocks progress
   - Who? When will it unblock? What's the impact?
4. **Update research** questions with findings
   - Converted "?" to "Answer is X" under Decisions

### Before end of work session or pause
1. **Sync to server**: `bn sync` or manually save in web UI
2. **Review open todos**: any incomplete? Add them if discovered
3. **Summarize blockers**: when will they unblock?
4. **Note context**: what state are you in? What's next?

### Example Session

```
Start: Read map, see 3 open todos + 1 blocker

Work:
  ✓ Implement editor modal (mark [x])
  ✓ Wire mutations (mark [x])
  → Discover new todo: "Add file upload component" (add to Todos)
  → Hit a blocker: "Need attachments mutation" (add to Blockers)
  ✓ Document the decision: Why we chose MCP tools over REST API
  
Pause:
  → Mark 2 todos done
  → Add 1 new todo (discovered during work)
  → Add 1 blocker (external dependency)
  → 1 decision logged (why we chose this approach)
  → Sync to server
```

---

## What makes good notes

**Good notes are:**
- ✅ Updated as you work, not at the end
- ✅ Specific ("Add file upload to Todos section" not "Finish feature")
- ✅ Include **why**, not just **what** (especially for decisions)
- ✅ Externally focused blockers (not your todos disguised as blockers)
- ✅ Questions you genuinely don't know answers to (To Research)
- ✅ Immediately synced after logical units complete
- ✅ Readable by someone else (or future-you) picking up the work

**Bad notes are:**
- ❌ Brain dump at end of session (memories fade, context lost)
- ❌ Vague ("stuff", "things", "features")
- ❌ Missing rationale (you know why now, future-you won't)
- ❌ Todos disguised as blockers ("Fix the tests" goes in Todos)
- ❌ Stale blockers (someone unblocked it, you forgot to remove)
- ❌ Only technical details (no "why did we make this choice")
- ❌ Never synced (changes lost if something crashes)

---

## Commands reference

**Read map:** `bnr cat`  
**Update todos:** Mark `[x]` in Todos section  
**Add todo:** `bnr add todo "description"`  
**Add decision:** `bnr add decision "Why we chose X"`  
**Add blocker:** `bnr add blocker "Blocked on Z, waiting for Y"`  
**Mark done:** `bnr done "todo name"` (fuzzy match)  
**Sync:** `bn sync` or save in web UI  
**View web:** http://localhost:1428/app/branch-notes

---

## For AI Agents

When working on a branch:

1. **Always start by reading the map** (`bnr cat` or the GraphQL query)
2. **Update continuously** — don't wait until done
3. **Mark todos immediately** when you finish them
4. **Log decisions with rationale** (why X over Y)
5. **Identify blockers early** and escalate
6. **Sync after each logical unit** completes (not just at end)
7. **Keep notes focused on future-you**: what context will be forgotten?

**Example good AI behavior:**
```
Read map → see Todos: ["implement editor", "add mutations", "test"]
Start: "Implementing editor modal"
Mid-work: Discover "need to refactor hooks" → add to Todos
Done: Mark "implement editor" [x], sync
Continue: "Now implementing mutations"
...
End of session: All changes in map, sync once more
```

**Example bad AI behavior:**
```
Start working, never check the map
Do work, dump notes at very end
Mark many things done in one sync
Miss what was already in Decisions (duplicate work)
```

---

## Summary

**Branch notes are alive when:**
- You update them as you work
- Todos checked off immediately (not batched)
- Decisions logged right after deciding
- Blockers identified and escalated early
- Map synced after logical units complete
- Context is documented for future readers (why, not just what)

**Use this skill whenever you:**
- Start work on a branch
- Finish a task
- Make a decision
- Hit a blocker
- Need context from prior sessions
- Hand off work to someone else
