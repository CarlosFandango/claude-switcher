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
# Switch with validation (recommended)
claude-switch switch <profile-name>

# Switch without validation (faster, skip API checks)
claude-switch switch <profile-name> --skip-validation
```

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
claude-switch delete <profile-name>
```

Removes:
- Profile configuration files
- Keychain entry (API key)
- Metadata
- Active marker (if deleting active profile)

## Model Management

**Note:** Model management is only available for LiteLLM profiles. Anthropic direct API profiles use Claude Code's default model selection.

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

### Switch Models

```bash
# Change to a different model
claude-switch model set <model-name>

# Example
claude-switch model set claude-sonnet-4-20250514
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
claude-switch model set claude-sonnet-4-20250514
# ... test ...

claude-switch model set claude-3-5-haiku-20241022
# ... test faster model ...

claude-switch model set claude-opus-4-20250514
# ... test most powerful model ...
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

## Claude Code CLI Integration

From within Claude Code, use the `/litellm` slash command:

```bash
# List available models
/litellm list

# Set model
/litellm set <model-name>

# Show current model
/litellm current
```

This provides in-session model switching without leaving Claude Code.

---

**See also:**
- [Quick Start Guide](QUICK_START.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Shell Integration](../SHELL_INTEGRATION.md)
