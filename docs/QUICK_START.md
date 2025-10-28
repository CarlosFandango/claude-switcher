# Quick Start Guide

Get up and running with claude-switch in 5 minutes!

## Installation

```bash
# Run installer from the repository directory
bash install.sh
```

The installer will:
- Install dependencies (curl, jq)
- Copy claude-switch to `/usr/local/bin`
- Launch the setup wizard

## Create Your First Profile

### Using LiteLLM (Company/Organization API)

```bash
claude-switch setup
```

Enter when prompted:
- **Profile name**: `work`
- **Description**: `Work LiteLLM proxy`
- **Base URL**: Your organization's endpoint (e.g., `https://litellm.company.com`)
- **API key**: Your LiteLLM API key (starts with `sk-`)
- **Model**: Select from the available models

### Using Personal Anthropic API

**Step 1:** Get your API key from https://console.anthropic.com/

**Step 2:** Create the profile

```bash
claude-switch create personal
```

Enter:
- **Base URL**: `https://api.anthropic.com`
- **API key**: Your Anthropic key (starts with `sk-ant-api`)
- **Model**: Model selection handled by Claude Code automatically

## Switch Between Profiles

```bash
# Interactive menu (use arrow keys to select)
claude-switch switch

# Or switch directly by name
claude-switch switch work
claude-switch switch personal

# Check which profile is active
claude-switch status
```

**Interactive Menu:**
- Use ↑/↓ arrow keys (or j/k) to navigate
- Press Enter to select
- Press 'q' to cancel
- Active profile marked with "(active)"

**Important:** Restart Claude Code or start a new session after switching.

## Add to Your Shell Prompt (Optional)

Show active profile in your prompt! See [Shell Integration](../SHELL_INTEGRATION.md) for:
- Spaceship Prompt
- Starship
- Powerlevel10k
- Other ZSH/Bash themes

## Common Commands

```bash
claude-switch list              # List all profiles
claude-switch status            # Show active profile and health
claude-switch delete <name>     # Delete a profile
claude-switch doctor            # Run diagnostics
claude-switch help              # Show all commands
```

## Next Steps

- [Full Usage Guide](USAGE.md) - All commands and options
- [Shell Integration](../SHELL_INTEGRATION.md) - Add to your prompt
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues

---

**Need help?** Run `claude-switch doctor` for diagnostics or check the [Troubleshooting Guide](TROUBLESHOOTING.md).
