# Global Claude Instructions

This file contains global instructions and learned context for Claude Code.

## User Preferences

- Document new Azure CLI patterns as they are discovered
- Keep track of Azure DevOps project details
- Prefer concise responses
- **Always create draft PRs** (use `--draft` flag) - never create ready PRs directly
- **Always use the `people-in-taskbar.md` PR template** when creating PRs for people-in-taskbar
  - Template is selected in ADO PR creation dropdown
  - Reference: `midgard/packages/people-in-taskbar/docs/Developer-guides/Making-a-change.md`
  - PR Guidelines: `midgard/packages/people-in-taskbar/docs/Guidelines/Pull-Request-guidance.md`
- **Always generate a change file** before creating PRs
- **Fix Node version mismatches** instead of working around them manually:
  ```bash
  yarn --ignore-engines 1js doctor node --fix
  ```

---

## Azure DevOps Project Details

### Organization & Project
- **Organization**: https://dev.azure.com/office
- **Project**: Office
- **Repository**: 1JS (monorepo)
- **Repository URL**: https://office.visualstudio.com/Office/_git/1JS

### User
- **Name**: Edwin Muraya
- **Email**: edwinmuraya@microsoft.com

### Common Area Paths
- `OC\M365 Companions\Shared\Shipped\Shell\DualFocusRefactor`

### Packages Worked On
- `@1js/people-in-taskbar`

---

## Change Files

**Always generate a change file before creating a PR.**

Reference: `midgard/packages/people-in-taskbar/docs/Developer-guides/Making-a-change.md`

### Using yarn change (preferred)
```bash
# From /midgard root
yarn change --type <type> --message "<description>"

# Types:
# - patch: Bug fixes, minor changes
# - minor: New features (backward compatible)
# - major: Breaking changes
```

### Manual Change File Creation (fallback)
If `yarn change` fails, create manually:

```bash
# Generate UUID
uuidgen | tr '[:upper:]' '[:lower:]'
# Example output: bfcf1db6-ea46-4ce1-bb6a-4f306f3578f4

# Create file at: midgard/change/change-<uuid>.json
```

```json
{
  "type": "patch",
  "comment": "Description of the change",
  "packageName": "@1js/people-in-taskbar",
  "email": "edwinmuraya@microsoft.com",
  "dependentChangeType": "patch"
}
```

---

## Azure CLI Reference

### Setup
```bash
# Install Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Install DevOps extension
az extension add --name azure-devops

# Login
az login

# Set defaults
az devops configure --defaults organization=https://dev.azure.com/office project=Office
```

### Pull Requests

```bash
# Create PR
az repos pr create --title "Title" --description "Description" --source-branch <branch> --target-branch main

# Create draft PR
az repos pr create --draft --title "Title" --source-branch <branch> --target-branch main

# Update PR description
az repos pr update --id <pr-id> --description "New description"

# Show PR details
az repos pr show --id <pr-id>

# List PRs
az repos pr list --status active

# Check PR policy/checks status
az repos pr policy list --id <pr-id> --query "[].{name:configuration.settings.displayName, status:status}" -o table

# Link work item to PR
az repos pr work-item add --id <pr-id> --work-items <work-item-id>

# List linked work items
az repos pr work-item list --id <pr-id>
```

### Work Items

```bash
# Query work items assigned to me
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.AssignedTo] = @me ORDER BY [System.CreatedDate] DESC"

# Query with filters
az boards query --wiql "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.AssignedTo] = @me AND [System.Title] CONTAINS 'flaky' AND [System.Title] CONTAINS 'e2e'"

# Get work item IDs only
az boards query --wiql "..." --query "[].id" -o tsv

# Show work item details
az boards work-item show --id <work-item-id>

# Create work item
az boards work-item create --type Bug --title "Title" --area "OC\M365 Companions\..."
```

### Pipelines

```bash
# List pipeline runs
az pipelines runs list --pipeline-ids <pipeline-id> --branch <branch> --top 5

# Run a pipeline
az pipelines run --name <pipeline-name>
```

### Output Formatting

```bash
# Table output
-o table

# JSON output
-o json

# TSV (for scripting)
-o tsv

# Query specific fields
--query "[].{id:id, title:fields.\"System.Title\"}"

# Query with filters
--query "[?status=='rejected']"
```

---

## M365 Companions App Config System

**Documentation**: `~/projects/PeopleInTaskbar/docs/Development/Features/App-Config-System.md`

The App Config system allows overriding configuration settings for development and testing without building the host locally.

### Config File Locations

| Level | Path |
|-------|------|
| Package-level | `%LocalAppData%\Microsoft\M365Companions\config.json` |
| Application-level | `%LocalAppData%\Microsoft\M365Companions\{APP}\config.json` |

For People app on WSL:
```
/mnt/c/Users/edwinmuraya/AppData/Local/Microsoft/M365Companions/People/config.json
```

**Important**: Restart the app after making changes.

### Common Configuration Options

| Setting | Type | Description |
|---------|------|-------------|
| `localHost` | Boolean | Connect to localhost instead of CDN |
| `localHostUrl` | String | Target URL for localhost (default: `https://127.0.0.1:9090`) |
| `clientBranch` | String | Point to a specific branch (e.g., `user/alias/my-branch`) |
| `clientVersion` | String | Point to specific CDN version (e.g., `1.20240215.7.0`) |
| `devTools` | Enum | Dev tools mode: `enabled`, `disabled`, `auto` |
| `remoteDebuggingPort` | Integer | Port for remote debugging (e.g., `9222`) |
| `lightDismiss` | Boolean | Enable/disable light dismiss of window |
| `autoUpdate` | Boolean | Whether to auto-update the app |
| `isTestMachine` | Boolean | Log telemetry to dev Kusto instead of prod |
| `ignoreCertificateErrors` | Boolean | Useful for local debugging |

### Example config.json

```json
{
  "devTools": "enabled",
  "clientBranch": "user/edwin/my-feature",
  "lightDismiss": false,
  "ignoreCertificateErrors": true,
  "remoteDebuggingPort": 9222,
  "localHost": false,
  "autoUpdate": false,
  "isTestMachine": true
}
```

### Override Priority

When multiple params are set: `localHost` > `clientBranch` > `clientVersion`

**Tip**: Set `localHost: false` when using branch or version overrides.

### Disabling a Setting

Prefix with underscore to disable without deleting:
```json
{
  "_clientBranch": "user/alias/old-branch",
  "clientBranch": "user/alias/new-branch"
}
```

---

## Learned Patterns

### 1JS Monorepo
- Use `yarn fast <package>` to install dependencies (from repo root)
- Use `yarn test-scope <package>` to run tests
- Use `yarn change --type patch --message "..."` to generate change files
- E2E tests use Playwright, run via `yarn test-e2e`
- Sparse checkout may hide files - use `git show HEAD:<path>` to read them

### Git Workflows
- Branch naming: `user/edwin/<feature-name>`
- Amend commits to keep PR history clean (single logical commit)
- Force push to personal branches is OK

---

*This file is automatically updated as new patterns are discovered.*
