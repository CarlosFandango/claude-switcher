# Troubleshooting Guide

Solutions to common issues with claude-switch.

## Quick Diagnostics

**Always start here:**

```bash
claude-switch doctor
```

This runs comprehensive health checks and often identifies the problem automatically.

## Common Issues

### "Failed to retrieve API key from keychain"

**Cause:** Keychain entry missing or corrupted.

**Solution:**
```bash
# Re-create the profile
claude-switch delete <profile-name>
claude-switch create <profile-name>
```

### "API key validation failed"

**Possible causes:**
1. Incorrect API key
2. Network connectivity issues
3. API endpoint unreachable

**Solutions:**

**Check API key format:**
```bash
# LiteLLM keys start with: sk-
# Anthropic keys start with: sk-ant-api
```

**Test endpoint connectivity:**
```bash
# For LiteLLM
curl https://your-litellm-endpoint.com/v1/models

# For Anthropic (will return 401 without auth, but confirms connectivity)
curl https://api.anthropic.com/v1/messages
```

**Re-create profile with correct key:**
```bash
claude-switch delete <profile-name>
claude-switch create <profile-name>
```

### "Model does not exist in available models list"

**Cause:** This should only happen with LiteLLM profiles (Anthropic profiles skip model validation).

**Solution:**

**Check available models:**
```bash
claude-switch switch <profile-name>
claude-switch model list
```

**Set a valid model:**
```bash
claude-switch model set <model-from-list>
```

### "Profile validation failed"

**Solution:**
```bash
# Run diagnostics first
claude-switch doctor

# If config is corrupted, re-create
claude-switch delete <profile-name>
claude-switch create <profile-name>
```

### Keychain Permission Prompts Keep Appearing

**Cause:** You clicked "Deny" or "Allow Once" instead of "Always Allow".

**Solution:**

1. Open **Keychain Access.app**
2. Search for `com.claude-switch`
3. Double-click the entry
4. Click **Access Control** tab
5. Select "Allow all applications to access this item"
6. Click **Save Changes**

Or simply delete and re-create the profile, clicking "Always Allow" this time.

### Profile Switched But Claude Code Still Uses Old Profile

**Cause:** Claude Code needs to reload settings.

**Solutions:**

**Option 1:** Restart Claude Code
```bash
# Exit Claude Code completely, then restart
```

**Option 2:** Start a new session
```bash
# In Claude Code, start a new conversation
```

**Verify the switch worked:**
```bash
claude-switch status
cat ~/.claude/settings.json | jq '.env.ANTHROPIC_BASE_URL'
```

### Shell Prompt Not Showing Active Profile

**Cause:** Shell integration not configured or prompt not reloaded.

**Solutions:**

See [Shell Integration Guide](../SHELL_INTEGRATION.md) for your specific prompt framework.

**Quick test:**
```bash
# Check if file exists
cat ~/.claude/active-profile

# Should show your active profile name
```

**Reload shell:**
```bash
exec zsh  # or exec bash
```

### "Command not found: claude-switch"

**Cause:** Not installed or not in PATH.

**Solution:**
```bash
# Re-run installer
cd /path/to/claude-switch
bash install.sh

# Verify installation
which claude-switch

# Should show: /usr/local/bin/claude-switch
```

### "jq: command not found" or "curl: command not found"

**Cause:** Missing dependencies.

**Solution:**
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install jq curl

# Verify
jq --version
curl --version
```

### Settings Keep Reverting

**Cause:** Another tool or process is overwriting `~/.claude/settings.json`.

**Check:**
```bash
# See what's modifying the file
ls -la ~/.claude/settings.json

# Check if Claude Code is creating default settings
```

**Solution:**

Ensure Claude Code is not configured to override settings. Check Claude Code documentation for configuration precedence.

### API Key Works in Browser But Not in claude-switch

**Cause:** Different API endpoints or key format issues.

**Verify:**

1. **Check the endpoint:**
   - Browser console API: `https://console.anthropic.com`
   - API endpoint for claude-switch: `https://api.anthropic.com`

2. **Ensure correct key type:**
   - Web UI keys may differ from API keys
   - Generate a new API key specifically for API use

**Get the correct key:**
```bash
# Visit: https://console.anthropic.com/settings/keys
# Create a new API key
# Copy the key (starts with sk-ant-api)
# Use in claude-switch
```

### Profile Deleted But Keychain Entry Remains

**Cause:** Manual deletion or incomplete cleanup.

**Solution:**
```bash
# Manually delete keychain entry
security delete-generic-password -s com.claude-switch.<profile-name> -a api-key

# Or use Keychain Access.app and search for com.claude-switch
```

### Can't Delete Active Profile

**Update:** This is now allowed! As of recent versions, you can delete the active profile.

If you're on an older version:
```bash
# Switch to another profile first
claude-switch switch <other-profile>

# Then delete
claude-switch delete <profile-to-delete>
```

## Advanced Troubleshooting

### Check Profile Configuration Files

```bash
# List all profiles
ls -la ~/.claude/profiles/

# Check specific profile config
cat ~/.claude/profiles/<name>/config.json | jq .

# Check metadata
cat ~/.claude/profiles/<name>/metadata.json | jq .
```

### Check Active Settings

```bash
# View current Claude Code settings
cat ~/.claude/settings.json | jq .

# Check which profile is active
cat ~/.claude/active-profile
```

### Manual Keychain Operations

```bash
# List all claude-switch keychain entries
security find-generic-password -s com.claude-switch

# Test retrieval for specific profile
security find-generic-password -s com.claude-switch.<profile-name> -a api-key -w
```

### Reset Everything

**Nuclear option - start fresh:**

```bash
# Backup current settings (optional)
cp -r ~/.claude ~/.claude.backup

# Remove all profiles
rm -rf ~/.claude/profiles/*
rm -f ~/.claude/active-profile

# Delete all keychain entries
security delete-generic-password -s com.claude-switch

# Re-run setup
claude-switch setup
```

## Getting Help

If you're still stuck:

1. **Run diagnostics:**
   ```bash
   claude-switch doctor > diagnostics.txt
   ```

2. **Check logs:**
   - Most errors are printed to stderr with detailed messages
   - Look for specific error codes or messages

3. **File an issue:**
   - Include output from `claude-switch doctor`
   - Include relevant error messages
   - Describe what you expected vs. what happened

4. **Check for updates:**
   ```bash
   cd /path/to/claude-switch
   git pull origin master
   bash install.sh
   ```

---

**See also:**
- [Quick Start Guide](QUICK_START.md)
- [Usage Guide](USAGE.md)
- [Shell Integration](../SHELL_INTEGRATION.md)
