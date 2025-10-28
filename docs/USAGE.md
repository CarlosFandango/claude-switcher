# Usage Guide

Complete reference for all claude-switch commands and features.

## Profile Management

### Create a Profile

```bash
# Interactive creation with wizard
claude-switch create

# Create with specific name
claude-switch create <profile-name>

# First-time setup wizard
claude-switch setup
```

### Switch Profiles

```bash
# Interactive menu (arrow-key navigation)
claude-switch switch

# Switch with validation (recommended)
claude-switch switch <profile-name>

# Switch without validation (faster, skip API checks)
claude-switch switch <profile-name> --skip-validation

# Interactive menu with skip validation
claude-switch switch --skip-validation
```

**Interactive Menu Features:**
- Use ↑/↓ arrow keys or j/k to navigate
- Press Enter to select
- Press 'q' to cancel
- Active profile is marked with "(active)"

**Note:** Restart Claude Code or start a new session after switching.

### List Profiles

```bash
# Show all profiles with status
claude-switch list
```

Output shows:
- ✓ Active profile (highlighted in green)
- Profile names
- Descriptions
- Base URLs
- Last used timestamps

### View Current Status

```bash
# Show active profile and configuration
claude-switch status
```

Shows:
- Active profile name
- API endpoint (LiteLLM vs Anthropic)
- Current model
- API connection health
- Configuration details

### Rename a Profile

```bash
claude-switch rename <old-name> <new-name>
```

Renames profile directory, updates keychain entries, and preserves active status.

### Delete a Profile

```bash
# Interactive menu (arrow-key navigation)
claude-switch delete

# Delete specific profile directly
claude-switch delete <profile-name>
```

**Interactive Menu Features:**
- Use ↑/↓ arrow keys or j/k to navigate
- Press Enter to select
- Press 'q' to cancel
- Active profile is marked with "(active)"
- Confirmation prompt before deletion

**What gets removed:**
- Profile configuration files
- Keychain entry (API key)
- Metadata
- Active marker (if deleting active profile)

## Model Management

**Note:** Model management is only available for LiteLLM and custom proxy profiles. Managed services (Anthropic, Vertex AI, AWS Bedrock) handle model selection internally.

### Switch Models

```bash
# Interactive menu (arrow-key navigation)
claude-switch model

# Or switch directly by name
claude-switch model <model-name>

# Example
claude-switch model claude-sonnet-4-20250514
```

**Interactive Menu Features:**
- Use ↑/↓ arrow keys or j/k to navigate
- Press Enter to select
- Press 'q' to cancel
- Current model is marked with "(current)"

### List Available Models

```bash
# Show all models from current profile's endpoint
claude-switch model list
```

### Show Current Model

```bash
# Display active model configuration
claude-switch model current
```

## Diagnostics

### Health Check

```bash
# Run comprehensive system diagnostics
claude-switch doctor
```

Checks:
- ✓ Dependencies (curl, jq)
- ✓ Configuration directory structure
- ✓ Profile configurations
- ✓ Keychain access
- ✓ API connectivity
- ✓ Claude Code settings

### Version Information

```bash
claude-switch version
```

### Help

```bash
# Show all commands
claude-switch help

# Quick reference
claude-switch
```

### Uninstall

```bash
# Run interactive uninstall wizard
claude-switch uninstall
```

**The uninstaller will:**
1. Show what will be removed (binary and library files)
2. Ask if you want to remove user data (profiles, settings)
3. Remove keychain entries for all profiles
4. Optionally remove shell integration

**What gets removed:**
- `/usr/local/bin/claude-switch` - Main executable
- `/usr/local/lib/claude-switch/` - Library modules

**Optional removal (you choose):**
- `~/.claude/profiles/` - All profile configurations
- `~/.claude/settings.json` - Active settings
- `~/.claude/active-profile` - Active profile marker
- Keychain entries - API keys for all profiles
- Shell integration files

**Note:** If you choose to preserve user data, you can reinstall claude-switch later and your profiles will still be available.

## Advanced Usage

### Verifying Active Profile

**Method 1: Using status command**
```bash
claude-switch status
```

**Method 2: Check settings file**
```bash
cat ~/.claude/settings.json | jq '.env.ANTHROPIC_BASE_URL'
```

**Method 3: Inside Claude Code**
Ask Claude: "What API endpoint are you using?"

### Multiple Environment Workflow

```bash
# Set up different environments
claude-switch create dev
claude-switch create staging
claude-switch create prod
claude-switch create personal

# Switch as needed
claude-switch switch dev       # Development work
claude-switch switch prod      # Production testing
claude-switch switch personal  # Personal projects
```

### Model Testing Workflow

```bash
# Switch to work profile
claude-switch switch work

# Test different models
claude-switch model claude-sonnet-4-20250514
# ... test ...

claude-switch model claude-3-5-haiku-20241022
# ... test faster model ...

claude-switch model claude-opus-4-20250514
# ... test most powerful model ...

# Or use interactive menu
claude-switch model
```

## Configuration Files

### Profile Configuration

Location: `~/.claude/profiles/<name>/config.json`

```json
{
  "model": "claude-sonnet-4-20250514",
  "base_url": "https://litellm.company.com",
  "small_model": "claude-3-5-haiku-20241022",
  "telemetry": false,
  "region": "us-east5"
}
```

**Note:** For Anthropic direct API profiles, the model field is a placeholder - Claude Code manages model selection.

### Profile Metadata

Location: `~/.claude/profiles/<name>/metadata.json`

```json
{
  "created": "2025-01-15T10:30:00Z",
  "last_used": "2025-01-15T14:22:00Z",
  "description": "Work LiteLLM profile"
}
```

### Active Settings

Location: `~/.claude/settings.json`

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<from-keychain>",
    "CLAUDE_CODE_ENABLE_TELEMETRY": "0",
    "ANTHROPIC_MODEL": "claude-sonnet-4-20250514",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-3-5-haiku-20241022",
    "ANTHROPIC_BASE_URL": "https://litellm.company.com",
    "CLOUD_ML_REGION": "us-east5"
  }
}
```

**Note:** For Anthropic profiles, `ANTHROPIC_MODEL` is omitted to use Claude Code's default.

## Security

### API Key Storage

API keys are **never** stored in files. They're kept in macOS Keychain:

- **Service**: `com.claude-switch.<profile-name>`
- **Account**: `api-key`

View/manage in Keychain Access.app under "login" keychain.

### Keychain Commands

```bash
# Store (done automatically by claude-switch)
security add-generic-password -s com.claude-switch.<profile> -a api-key -w <key>

# Retrieve (done automatically by claude-switch)
security find-generic-password -s com.claude-switch.<profile> -a api-key -w

# Delete (done automatically when deleting profile)
security delete-generic-password -s com.claude-switch.<profile> -a api-key
```

### Permissions

First access to each profile's keychain entry prompts for permission. Click **"Always Allow"** to avoid repeated prompts.

---

**See also:**
- [Quick Start Guide](QUICK_START.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Shell Integration](../SHELL_INTEGRATION.md)
