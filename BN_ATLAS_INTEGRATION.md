# bn ↔ Atlas Integration

## Overview

Updated `~/.bin/bn` to post branch notes to Atlas server while maintaining local fallback for offline support.

## How It Works

### Architecture
```
bn command
  ├→ Try: POST to Atlas via bnr CLI
  ├→ Success: Cache response locally + return
  └→ Fail: Use local file system
```

### Key Changes

1. **Atlas-aware commands:**
   - `bn cat` — fetch from server, fall back to local cache
   - `bn add <section> <text>` — post to server, fall back to local
   - `bn done "<task>"` — update on server, fall back to local
   - `bn status` — fetch from server, fall back to local

2. **Configuration:**
   - Enable/disable with: `export BN_USE_ATLAS=true|false`
   - Default: `BN_USE_ATLAS=true` (uses Atlas if available)
   - Requires: `~/.config/bn/config.json` (from bnr setup)

3. **Offline Fallback:**
   - If server unreachable → uses local files
   - No data loss, fully backwards compatible
   - Automatic local caching

4. **Unchanged commands** (still local-only):
   - `bn files` — investigation files
   - `bn script` — script management
   - `bn build` — runs scripts locally
   - `bn cron`, `bn run`, etc. — work management

## Testing

```bash
# Verify Atlas is running and configured
bnr status

# Test posting to server
bn add todo "Test task"  # Should post to Atlas

# Check local fallback
pkill -f "dotnet run"  # Stop Atlas
bn cat               # Should show [OFFLINE] + cached version

# Auto-reconnect
# (restart Atlas)
bn cat               # Should show live data again
```

## Implementation Details

- Added helper functions: `_atlas_available()`, `_try_atlas_or_local()`
- Each command tries Atlas first, falls back to existing local logic
- No breaking changes to the `bn` interface
- 100% backwards compatible

## Benefits

✅ Server as source of truth for branch notes
✅ All operations sync with Atlas
✅ Offline support via local cache
✅ No user retraining needed (same commands)
✅ Gradual migration (scripts still local)
✅ Can disable with `export BN_USE_ATLAS=false`
