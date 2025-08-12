# Installation Guide

## Quick Installation (Recommended)

For automated installation with all dependencies and setup:

```bash
# Clone or download the repository
cd claude-switch

# Run the automated installer
chmod +x install.sh
./install.sh
```

The installer will:
- Check for AI CLI (and prompt to install if missing)
- Install required dependencies (jq, curl)
- Install the main script to `/usr/local/bin/`
- Set up AI CLI integration
- Guide you through initial configuration

## Prerequisites

The installer will check for these automatically, but you can verify manually:

### Required: AI CLI
This tool requires an AI CLI to be installed first:

```bash
# Check if AI CLI is available
command -v claude >/dev/null 2>&1 && echo "AI CLI found" || echo "AI CLI not found"
```

**To install AI CLI:**
1. Visit: https://docs.anthropic.com/en/docs/claude-code/quickstart
2. Follow installation instructions for your platform
3. Quick install (macOS): `curl -fsSL https://claude.ai/install.sh | sh`

### Dependencies (Auto-installed)
- `jq` - JSON processing
- `curl` - API calls

## Manual Installation

If you prefer manual installation or the automated installer fails:

### Step 1: Install Dependencies

```bash
# macOS
brew install jq curl

# Ubuntu/Debian
sudo apt-get install jq curl

# CentOS/RHEL
sudo yum install jq curl
```

### Step 2: Install Main Script

```bash
# Make the script executable
chmod +x claude-switch

# Copy to system path
sudo cp claude-switch /usr/local/bin/

# Verify installation
claude-switch help
```

### Step 3: Install AI CLI Integration

```bash
# Create commands directory if it doesn't exist
mkdir -p ~/.claude/commands/

# Copy the slash command
cp litellm.md ~/.claude/commands/

# Verify installation by starting your AI CLI and typing:
# /litellm
```

### Step 4: Initial Setup

#### Personal Configuration
If you already have an AI configuration, it will be automatically backed up as your "personal" profile on first use.

#### Work Configuration (LiteLLM)
```bash
# Set up work profile - you'll be prompted for your LiteLLM API key
claude-switch work
```

### Step 5: Verification

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