# AI Configuration Switcher

A bash utility for managing AI configuration profiles and LiteLLM model switching.

## Features

- **Profile Management**: Switch between personal and work AI configurations
- **LiteLLM Integration**: List and switch between available LiteLLM models
- **Configuration Backup**: Automatic backup and restore of configuration profiles
- **Real-time Model Discovery**: Fetch available models from LiteLLM endpoint

## Installation

1. Copy the `claude-switch` script to `/usr/local/bin/`:
   ```bash
   cp claude-switch /usr/local/bin/
   chmod +x /usr/local/bin/claude-switch
   ```

2. Install the slash command (optional):
   ```bash
   cp litellm.md ~/.claude/commands/
   ```

## Usage

### Profile Management

```bash
# Switch to personal configuration
claude-switch personal

# Switch to work configuration (LiteLLM)
claude-switch work

# Show current configuration status
claude-switch status

# Backup current configuration
claude-switch backup <name>
```

### Model Management

```bash
# List available models
claude-switch model list

# Switch to specific model
claude-switch model set <model-name>

# Show current model
claude-switch model current
```

### Slash Command (AI CLI Integration)

If you've installed the `litellm.md` file, you can use these commands directly in your AI CLI:

```
/litellm list
/litellm set claude-sonnet-4-20250514
/litellm current
```

## Configuration

The tool manages configurations in `~/.claude/profiles/`:
- `personal/` - Personal AI configuration
- `work/` - Work/LiteLLM configuration

### Work Configuration Setup

On first run of `claude-switch work`, you'll be prompted to enter your LiteLLM API key. The tool will create a configuration with:

- Custom LiteLLM base URL
- Model preferences
- Telemetry settings

## Requirements

- `bash`
- `jq` (for JSON processing)
- `curl` (for API calls)

## Example Workflow

```bash
# Set up work profile
claude-switch work

# List available models
claude-switch model list

# Switch to a specific model
claude-switch model set claude-3-5-haiku-20241022

# Check current status
claude-switch status

# Switch back to personal
claude-switch personal
```

## Security Note

API keys are stored in local configuration files. Ensure proper file permissions and avoid committing configurations to version control.