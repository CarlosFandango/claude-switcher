# Claude Switch

**Secure, flexible profile management for Claude Code with keychain integration**

Claude Switch lets you seamlessly manage multiple Claude API configurations with secure keychain storage, live validation, and an intuitive command-line interface.

## Features

- **🔐 Secure Storage**: API keys stored in macOS Keychain, never on disk
- **✅ Live Validation**: Automatically validates API keys and models before switching
- **🚀 Multiple Profiles**: Create unlimited named profiles for different contexts
- **🧙 Setup Wizard**: Interactive guided setup for first-time users
- **📊 Status Dashboard**: View current configuration and API health at a glance
- **🔄 Easy Switching**: Switch between profiles with a single command
- **🏥 Health Checks**: Built-in diagnostics with `doctor` command
- **🎯 Model Management**: List and switch between available LiteLLM models

## Requirements

- macOS (for keychain integration)
- Claude Code CLI installed
- `curl` and `jq` (auto-installed via Homebrew)

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-switch.git
cd claude-switch

# Run automated installation
bash install.sh
```

The installer will:
1. Check dependencies and install if missing
2. Install claude-switch to `/usr/local/bin`
3. Set up Claude Code CLI integration
4. Run the interactive setup wizard

### Setting Up Your Profiles

Claude Switch supports multiple profile types. Here's how to set up the most common configurations:

#### Option 1: LiteLLM / Hosted Proxy Setup

If you're using a hosted LiteLLM proxy (like your organization's API gateway):

```bash
claude-switch setup
```

The wizard will prompt you for:
1. **Profile name**: Choose a name (e.g., `work`, `company`)
2. **Description**: Optional description (e.g., "Work LiteLLM proxy")
3. **Base URL**: Your LiteLLM endpoint (e.g., `https://litellm.example.com`)
4. **API key**: Your LiteLLM API key (starts with `sk-`)
5. **Model selection**: Choose from available models on your proxy

Example:
```bash
$ claude-switch setup

Enter profile name: work
Enter profile description: Work LiteLLM proxy
Enter LiteLLM base URL: https://litellm.example.com
Enter your API key: sk-your-litellm-key-here
✓ API key is valid
✓ Found 10 available models

Select model number (1-10): 1
✓ Profile 'work' created successfully!
```

#### Option 2: Personal Anthropic API Setup

If you're using a personal Claude subscription via Anthropic's API:

**Step 1: Get Your API Key**
1. Go to https://console.anthropic.com/
2. Log in with your Claude account
3. Click **API Keys** in the left sidebar
4. Click **"Create Key"** or copy an existing one
5. Copy the API key (starts with `sk-ant-api...`)

**Step 2: Create Profile**
```bash
claude-switch create
```

Enter when prompted:
- **Profile name**: `personal` (or any name you prefer)
- **Description**: `Personal Anthropic API`
- **Base URL**: `https://api.anthropic.com`
- **API key**: [paste your key from Step 1]
- **Model**: Select from Anthropic's available models

Example:
```bash
$ claude-switch create

Enter profile name: personal
Enter profile description: Personal Anthropic API
Enter LiteLLM base URL: https://api.anthropic.com
Enter your API key: sk-ant-api03-your-key-here
✓ API key is valid
✓ Found 5 available models

  1) claude-opus-4-20250514
  2) claude-sonnet-4-20250514
  3) claude-3-5-sonnet-20241022
  4) claude-3-5-haiku-20241022
  5) claude-3-opus-20240229

Select model number (1-5): 2
✓ Profile 'personal' created successfully!
```

#### Switching Between Profiles

Once you've set up multiple profiles, switch between them easily:

```bash
# Switch to work profile (LiteLLM)
claude-switch switch work

# Switch to personal profile (Anthropic direct)
claude-switch switch personal

# Check which profile is active
claude-switch status

# List all profiles
claude-switch list
```

**Note**: After switching profiles, restart Claude Code CLI or start a new session for changes to take effect.

## Usage

### Profile Management

```bash
# Create a new profile interactively
claude-switch create

# Create a profile with specific name
claude-switch create work

# List all profiles
claude-switch list

# Switch to a profile (with validation)
claude-switch switch work

# Switch without validation (faster)
claude-switch switch work --skip-validation

# Show current configuration and status
claude-switch status

# Rename a profile
claude-switch rename old-name new-name

# Delete a profile
claude-switch delete profile-name
```

### Model Management

```bash
# List available models from LiteLLM
claude-switch model list

# Show current model
claude-switch model current

# Switch to a different model
claude-switch model set claude-sonnet-4-20250514
```

### Diagnostics

```bash
# Run comprehensive health checks
claude-switch doctor

# Show version
claude-switch version

# Show help
claude-switch help
```

### Claude Code CLI Integration

From within Claude Code CLI, use the `/litellm` slash command:

```bash
# List models
/litellm list

# Set model
/litellm set model-name

# Show current model
/litellm current
```

## Architecture

### Modular Structure

```
claude-switch/
├── claude-switch          # Main executable
├── lib/                   # Modular libraries
│   ├── ui.sh             # User interface components
│   ├── config.sh         # Configuration management
│   ├── validation.sh     # API validation functions
│   ├── api.sh            # LiteLLM API interactions
│   ├── core.sh           # Profile management & keychain
│   └── wizard.sh         # Interactive setup wizard
├── install.sh            # Automated installer
└── litellm.md            # Claude Code slash command
```

### Profile Storage

```
~/.claude/
├── settings.json          # Active configuration
├── active-profile         # Currently active profile name
└── profiles/
    ├── work/
    │   ├── config.json    # Model & URL settings
    │   └── metadata.json  # Created/last used timestamps
    └── personal/
        ├── config.json
        └── metadata.json
```

API keys are **never** stored in files - they're kept securely in macOS Keychain under:
- Service: `com.claude-switch.<profile-name>`
- Account: `api-key`

### Live Validation

When switching profiles, claude-switch:
1. Retrieves API key from keychain
2. Validates key format
3. Tests API connection (`GET /v1/models`)
4. Verifies selected model exists
5. Only applies configuration if all checks pass
6. Provides rollback on failure

### Verifying Your Active Profile

After switching profiles, you can verify which profile Claude Code is using:

**1. Check with claude-switch:**
```bash
claude-switch status
```

This shows:
- Current profile name
- API endpoint (LiteLLM vs Anthropic)
- Active model
- API connection health

**2. Inside Claude Code:**

Ask Claude directly:
```
What API endpoint are you using?
```

Or check which profile is active:
```bash
claude-switch list
```
(The active profile is highlighted in green)

**3. Verify in settings file:**
```bash
cat ~/.claude/settings.json
```

Look for:
- `ANTHROPIC_BASE_URL: "https://litellm.example.com"` → Work profile
- `ANTHROPIC_BASE_URL: "https://api.anthropic.com"` → Personal profile

**Important**: After switching profiles, you may need to restart Claude Code CLI or start a new chat session for the changes to take effect.

## Configuration Format

### Profile Config (`config.json`)

```json
{
  "model": "claude-sonnet-4-20250514",
  "base_url": "https://litellm.example.com",
  "small_model": "claude-3-5-haiku-20241022",
  "telemetry": false,
  "region": "us-east5"
}
```

### Profile Metadata (`metadata.json`)

```json
{
  "created": "2025-01-15T10:30:00Z",
  "last_used": "2025-01-15T14:22:00Z",
  "description": "Work LiteLLM profile"
}
```

### Active Settings (`settings.json`)

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<retrieved-from-keychain>",
    "CLAUDE_CODE_ENABLE_TELEMETRY": "0",
    "ANTHROPIC_MODEL": "claude-sonnet-4-20250514",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-3-5-haiku-20241022",
    "ANTHROPIC_BASE_URL": "https://litellm.example.com",
    "CLOUD_ML_REGION": "us-east5"
  }
}
```

## Examples

### Multi-Environment Workflow

```bash
# Set up profiles for different environments
claude-switch create dev        # Development LiteLLM
claude-switch create staging    # Staging LiteLLM
claude-switch create prod       # Production LiteLLM
claude-switch create personal   # Direct Anthropic API

# Switch as needed
claude-switch switch dev
# ... work on development ...

claude-switch switch prod
# ... check production behavior ...

claude-switch switch personal
# ... use personal API key ...
```

### Model Testing

```bash
# Switch profile and test different models
claude-switch switch work

# Try different models
claude-switch model set claude-sonnet-4-20250514
# ... test ...

claude-switch model set claude-3-5-haiku-20241022
# ... test faster model ...

claude-switch model set claude-opus-4-20250514
# ... test most powerful model ...
```

### Troubleshooting

```bash
# Check system health
claude-switch doctor

# View current configuration
claude-switch status

# List all profiles
claude-switch list

# Re-run setup if needed
claude-switch setup
```

## Security

- **API Keys**: Stored in macOS Keychain, never in files
- **Permissions**: Configuration files are user-readable only
- **Validation**: API keys tested before use
- **No Transmission**: Keys only sent to configured LiteLLM endpoint

### Keychain Access

Claude Switch uses the macOS `security` command to:
- Store: `security add-generic-password -s com.claude-switch.<profile> -a api-key -w <key>`
- Retrieve: `security find-generic-password -s com.claude-switch.<profile> -a api-key -w`
- Delete: `security delete-generic-password -s com.claude-switch.<profile> -a api-key`

You can view/manage entries in Keychain Access.app under "login" keychain.

## Upgrading from v1.x

If you're upgrading from the old version:

1. **Backup your API keys** - old version stored them in plaintext
2. **Run new installer**: `bash install.sh`
3. **Run setup wizard**: `claude-switch setup`
4. **Re-create profiles** with your existing API keys (they'll be stored securely)
5. **Remove old backups**: `rm -rf ~/.claude/profiles/{personal,work}` (after confirming new profiles work)

The new version is **not backward compatible** but provides a much more secure and flexible system.

## Troubleshooting

### "Failed to retrieve API key from keychain"

The keychain entry might be missing or corrupted.

```bash
# Re-create the profile
claude-switch delete problem-profile
claude-switch create problem-profile
```

### "API key validation failed"

- Check your API key is correct
- Verify LiteLLM endpoint is accessible
- Test connection: `curl https://litellm.example.com/v1/models`

### "Profile validation failed"

Run diagnostics:

```bash
claude-switch doctor
```

### Keychain Permission Prompts

First-time access to each profile's keychain entry will prompt for permission. Click "Always Allow" to avoid repeated prompts.

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test thoroughly with `claude-switch doctor`
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file

## Changelog

### v2.0.0 (2025-01-XX)

**Breaking Changes:**
- Complete rewrite with modular architecture
- Keychain-based API key storage (not backward compatible)
- New command structure

**New Features:**
- 🔐 Secure keychain integration
- ✅ Live API validation
- 🎯 Unlimited named profiles
- 🧙 Interactive setup wizard
- 🏥 Health diagnostics (`doctor` command)
- 📊 Enhanced status dashboard
- 🔄 Profile rename support
- 📦 Modular codebase (lib/)

**Improvements:**
- Better error handling with rollback
- Colored, user-friendly output
- Comprehensive validation
- Automated installation
- Improved documentation

### v1.0.0

- Initial release
- Basic personal/work profile switching
- LiteLLM model management

## Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Check existing documentation
- Run `claude-switch doctor` for diagnostics

---

Made with ❤️ for the Claude Code community
