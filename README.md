# Claude Switch

**Secure profile management for Claude Code with keychain integration**

Easily switch between multiple Claude API configurations (work, personal, different environments) with secure API key storage and live validation.

```bash
# Interactive menu - just run switch without arguments
claude-switch switch

# Or switch directly by name
claude-switch switch work
claude-switch switch personal

# Check status
claude-switch status
```

## Features

- 🔐 **Secure Storage** - API keys in macOS Keychain, never on disk
- 🚀 **Multiple Profiles** - Unlimited named profiles (work, personal, dev, staging, etc.)
- ✅ **Live Validation** - API key and model validation before switching
- 🎯 **Interactive Menu** - Arrow-key navigation for switch and delete commands
- 💻 **Shell Integration** - Show active profile in your prompt
- 🧙 **Setup Wizard** - Interactive guided setup
- 🏥 **Diagnostics** - Built-in health checks with `doctor` command

## Quick Start

```bash
# Install
bash install.sh

# Create your first profile
claude-switch setup

# Switch profiles with interactive menu
claude-switch switch

# Or switch directly
claude-switch switch work

# Check status
claude-switch status
```

**📖 [Full Quick Start Guide](docs/QUICK_START.md)**

## Documentation

- **[Quick Start](docs/QUICK_START.md)** - Get up and running in 5 minutes
- **[Usage Guide](docs/USAGE.md)** - Complete command reference
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Solutions to common issues
- **[Shell Integration](SHELL_INTEGRATION.md)** - Add profile to your prompt

## Requirements

- macOS (for keychain integration)
- Claude Code CLI installed
- curl and jq (auto-installed via Homebrew)

## Common Commands

```bash
claude-switch create          # Create new profile
claude-switch switch          # Interactive menu to switch profiles
claude-switch switch <name>   # Switch to specific profile
claude-switch list            # List all profiles
claude-switch status          # Show active profile
claude-switch delete          # Interactive menu to delete profile
claude-switch delete <name>   # Delete specific profile
claude-switch doctor          # Run diagnostics
claude-switch uninstall       # Uninstall claude-switch
claude-switch help            # Show all commands
```

## Profile Types

### LiteLLM / Hosted Proxy

For organization/company API gateways:

```bash
claude-switch create work
# Base URL: https://litellm.company.com
# API Key: sk-your-litellm-key
# Model: Select from available models
```

### Personal Anthropic API

For direct Anthropic API access:

1. Get API key from https://console.anthropic.com/
2. Create profile:

```bash
claude-switch create personal
# Base URL: https://api.anthropic.com
# API Key: sk-ant-api03-your-key-here
# Model: Handled by Claude Code (default)
```

## Shell Integration

Show active profile in your prompt!

### Spaceship Prompt (Oh My Zsh)

```bash
# Create custom section
cat > ~/.oh-my-zsh/custom/claude_profile.zsh << 'EOF'
spaceship_claude_profile() {
  [[ $SPACESHIP_VERSION ]] || return
  local profile_file="$HOME/.claude/active-profile"
  [[ -f "$profile_file" ]] || return
  local profile=$(cat "$profile_file")
  spaceship::section --color cyan --symbol '󰧑 ' "$profile"
}
EOF

# Add to ~/.zshrc before Oh My Zsh loads
SPACESHIP_RPROMPT_ORDER=(
  claude_profile
  time
  exec_time
)
```

Result: `󰧑 work` or `󰧑 personal` appears in your prompt!

**📖 [Full Shell Integration Guide](SHELL_INTEGRATION.md)** - Starship, Powerlevel10k, and more

## How It Works

### Profile Storage

```
~/.claude/
├── settings.json       # Active configuration (used by Claude Code)
├── active-profile      # Currently active profile name
└── profiles/
    ├── work/
    │   ├── config.json     # Model & endpoint settings
    │   └── metadata.json   # Timestamps & description
    └── personal/
        ├── config.json
        └── metadata.json
```

### Secure API Keys

API keys are **never** stored in files. They're kept in macOS Keychain:

- **Service**: `com.claude-switch.<profile-name>`
- **Account**: `api-key`

View/manage in Keychain Access.app

### Validation Process

When switching profiles, claude-switch:
1. Retrieves API key from keychain
2. Validates key format
3. Tests API connection
4. Verifies model availability (LiteLLM only)
5. Applies configuration to Claude Code
6. Provides rollback on failure

## Architecture

**Modular design** with separated concerns:

```
lib/
├── ui.sh           # User interface & colored output
├── config.sh       # Configuration management
├── validation.sh   # API validation
├── api.sh          # LiteLLM API interactions
├── core.sh         # Profile management & keychain
└── wizard.sh       # Interactive setup wizard
```

## Troubleshooting

```bash
# Run comprehensive diagnostics
claude-switch doctor

# Common issues:
claude-switch delete <profile>  # Fix corrupted profile
claude-switch create <profile>  # Re-create from scratch

# Check what's active
cat ~/.claude/active-profile
cat ~/.claude/settings.json
```

**📖 [Full Troubleshooting Guide](docs/TROUBLESHOOTING.md)**

## Security

- ✅ API keys stored in macOS Keychain only
- ✅ Configuration files are user-readable only
- ✅ Live validation before use
- ✅ No transmission except to configured endpoint
- ✅ Secure cleanup on profile deletion

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test with `claude-switch doctor`
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) file

## Support

- **Diagnostics**: Run `claude-switch doctor`
- **Documentation**: See [docs/](docs/) directory
- **Issues**: File an issue on GitHub

---

**Made with ❤️ for the Claude Code community**
