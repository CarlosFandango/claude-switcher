#!/bin/bash
# Configuration File Operations

# Base directories
CLAUDE_CONFIG_DIR="$HOME/.claude"
PROFILES_DIR="$CLAUDE_CONFIG_DIR/profiles"
ACTIVE_PROFILE_FILE="$CLAUDE_CONFIG_DIR/active-profile"
SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"

# Ensure configuration directories exist
init_config_dirs() {
    mkdir -p "$CLAUDE_CONFIG_DIR"
    mkdir -p "$PROFILES_DIR"
}

# Get the currently active profile name
get_active_profile() {
    if [ -f "$ACTIVE_PROFILE_FILE" ]; then
        cat "$ACTIVE_PROFILE_FILE"
    else
        echo ""
    fi
}

# Set the active profile
set_active_profile() {
    local profile_name="$1"
    echo "$profile_name" > "$ACTIVE_PROFILE_FILE"
}

# Check if a profile exists
profile_exists() {
    local profile_name="$1"
    [ -d "$PROFILES_DIR/$profile_name" ]
}

# Get profile directory path
get_profile_dir() {
    local profile_name="$1"
    echo "$PROFILES_DIR/$profile_name"
}

# Get profile config file path
get_profile_config() {
    local profile_name="$1"
    echo "$PROFILES_DIR/$profile_name/config.json"
}

# Get profile metadata file path
get_profile_metadata() {
    local profile_name="$1"
    echo "$PROFILES_DIR/$profile_name/metadata.json"
}

# List all profile names
list_profiles() {
    if [ ! -d "$PROFILES_DIR" ]; then
        return
    fi

    for profile_dir in "$PROFILES_DIR"/*; do
        if [ -d "$profile_dir" ]; then
            basename "$profile_dir"
        fi
    done
}

# Create profile configuration
create_profile_config() {
    local profile_name="$1"
    local model="$2"
    local base_url="$3"
    local small_model="${4:-claude-3-5-haiku-20241022}"

    local config_file
    config_file="$(get_profile_config "$profile_name")"

    cat > "$config_file" << EOF
{
  "model": "$model",
  "base_url": "$base_url",
  "small_model": "$small_model",
  "telemetry": false,
  "region": "us-east5"
}
EOF
}

# Create profile metadata
create_profile_metadata() {
    local profile_name="$1"
    local description="$2"

    local metadata_file
    metadata_file="$(get_profile_metadata "$profile_name")"

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$metadata_file" << EOF
{
  "created": "$timestamp",
  "last_used": "$timestamp",
  "description": "$description"
}
EOF
}

# Update last used timestamp in metadata
update_last_used() {
    local profile_name="$1"
    local metadata_file
    metadata_file="$(get_profile_metadata "$profile_name")"

    if [ ! -f "$metadata_file" ]; then
        return 1
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Use jq to update the last_used field
    local temp_file="${metadata_file}.tmp"
    jq --arg ts "$timestamp" '.last_used = $ts' "$metadata_file" > "$temp_file"
    mv "$temp_file" "$metadata_file"
}

# Read config value from profile
get_config_value() {
    local profile_name="$1"
    local key="$2"
    local config_file
    config_file="$(get_profile_config "$profile_name")"

    if [ ! -f "$config_file" ]; then
        return 1
    fi

    jq -r ".$key // empty" "$config_file"
}

# Read metadata value from profile
get_metadata_value() {
    local profile_name="$1"
    local key="$2"
    local metadata_file
    metadata_file="$(get_profile_metadata "$profile_name")"

    if [ ! -f "$metadata_file" ]; then
        return 1
    fi

    jq -r ".$key // empty" "$metadata_file"
}

# Update config value in profile
update_config_value() {
    local profile_name="$1"
    local key="$2"
    local value="$3"
    local config_file
    config_file="$(get_profile_config "$profile_name")"

    if [ ! -f "$config_file" ]; then
        return 1
    fi

    local temp_file="${config_file}.tmp"
    jq --arg val "$value" ".$key = \$val" "$config_file" > "$temp_file"
    mv "$temp_file" "$config_file"
}

# Apply profile to active Claude configuration
apply_profile() {
    local profile_name="$1"
    local api_key="$2"

    local config_file
    config_file="$(get_profile_config "$profile_name")"

    if [ ! -f "$config_file" ]; then
        return 1
    fi

    # Read configuration values
    local model base_url small_model region
    model=$(jq -r '.model' "$config_file")
    base_url=$(jq -r '.base_url' "$config_file")
    small_model=$(jq -r '.small_model' "$config_file")
    region=$(jq -r '.region // "us-east5"' "$config_file")

    # Create settings.json
    cat > "$SETTINGS_FILE" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "$api_key",
    "CLAUDE_CODE_ENABLE_TELEMETRY": "0",
    "ANTHROPIC_MODEL": "$model",
    "ANTHROPIC_SMALL_FAST_MODEL": "$small_model",
    "ANTHROPIC_BASE_URL": "$base_url",
    "CLOUD_ML_REGION": "$region"
  }
}
EOF

    # Update last used timestamp
    update_last_used "$profile_name"
}

# Delete a profile
delete_profile() {
    local profile_name="$1"
    local profile_dir
    profile_dir="$(get_profile_dir "$profile_name")"

    if [ -d "$profile_dir" ]; then
        rm -rf "$profile_dir"
        return 0
    fi
    return 1
}

# Rename a profile
rename_profile() {
    local old_name="$1"
    local new_name="$2"

    local old_dir new_dir
    old_dir="$(get_profile_dir "$old_name")"
    new_dir="$(get_profile_dir "$new_name")"

    if [ ! -d "$old_dir" ]; then
        return 1
    fi

    if [ -d "$new_dir" ]; then
        return 2
    fi

    mv "$old_dir" "$new_dir"

    # Update active profile if it was the renamed one
    local active
    active=$(get_active_profile)
    if [ "$active" = "$old_name" ]; then
        set_active_profile "$new_name"
    fi
}

# Validate profile name format
validate_profile_name() {
    local name="$1"

    # Must not be empty
    if [ -z "$name" ]; then
        return 1
    fi

    # Must match alphanumeric, dash, underscore only
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 1
    fi

    return 0
}
