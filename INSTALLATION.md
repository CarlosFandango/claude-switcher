# Installation Guide

## Prerequisites

Before installing, ensure you have the following tools available:

```bash
# Check for required tools
command -v jq >/dev/null 2>&1 || echo "jq is required - install with: brew install jq"
command -v curl >/dev/null 2>&1 || echo "curl is required"
```

## Step 1: Install Main Script

```bash
# Make the script executable
chmod +x claude-switch

# Copy to system path
sudo cp claude-switch /usr/local/bin/

# Verify installation
claude-switch help
```

## Step 2: Install AI CLI Integration (Optional)

If you're using an AI CLI that supports slash commands:

```bash
# Create commands directory if it doesn't exist
mkdir -p ~/.claude/commands/

# Copy the slash command
cp litellm.md ~/.claude/commands/

# Verify installation by starting your AI CLI and typing:
# /litellm
```

## Step 3: Initial Setup

### Personal Configuration

If you already have an AI configuration, it will be automatically backed up as your "personal" profile on first use.

### Work Configuration (LiteLLM)

```bash
# Set up work profile - you'll be prompted for your LiteLLM API key
claude-switch work
```

This will create a work configuration with:
- Your LiteLLM API endpoint
- Default model preferences
- Optimized settings for work use

## Step 4: Verification

```bash
# Check status
claude-switch status

# List available models (requires work profile)
claude-switch model list

# Test profile switching
claude-switch personal
claude-switch work
```

## Troubleshooting

### Permission Issues
```bash
# If you get permission errors
sudo chown $USER:staff /usr/local/bin/claude-switch
chmod 755 /usr/local/bin/claude-switch
```

### Missing jq
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

### API Connection Issues
- Verify your LiteLLM endpoint is accessible
- Check your API key is valid
- Ensure firewall/network allows HTTPS connections

## Uninstallation

```bash
# Remove main script
sudo rm /usr/local/bin/claude-switch

# Remove slash command (optional)
rm ~/.claude/commands/litellm.md

# Remove configuration profiles (optional)
rm -rf ~/.claude/profiles
```