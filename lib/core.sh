#!/bin/bash
# Core Profile Management Functions

# Keychain service name prefix
KEYCHAIN_SERVICE="com.claude-switch"

# Store API key in macOS Keychain
keychain_store() {
    local profile_name="$1"
    local api_key="$2"

    local service="${KEYCHAIN_SERVICE}.${profile_name}"

    # Delete existing entry if present (to update)
    security delete-generic-password -s "$service" -a "api-key" 2>/dev/null

    # Add new entry
    security add-generic-password \
        -s "$service" \
        -a "api-key" \
        -w "$api_key" \
        -U 2>/dev/null

    return $?
}

# Retrieve API key from macOS Keychain
keychain_retrieve() {
    local profile_name="$1"
    local service="${KEYCHAIN_SERVICE}.${profile_name}"

    local api_key
    api_key=$(security find-generic-password \
        -s "$service" \
        -a "api-key" \
        -w 2>/dev/null)

    local result=$?

    if [ $result -eq 0 ] && [ -n "$api_key" ]; then
        echo "$api_key"
        return 0
    fi

    return 1
}

# Delete API key from macOS Keychain
keychain_delete() {
    local profile_name="$1"
    local service="${KEYCHAIN_SERVICE}.${profile_name}"

    security delete-generic-password -s "$service" -a "api-key" 2>/dev/null
    return $?
}

# Check if API key exists in keychain
keychain_exists() {
    local profile_name="$1"
    local service="${KEYCHAIN_SERVICE}.${profile_name}"

    security find-generic-password -s "$service" -a "api-key" 2>/dev/null > /dev/null
    return $?
}

# Create a new profile
create_profile() {
    local profile_name="$1"
    local api_key="$2"
    local model="$3"
    local base_url="$4"
    local description="${5:-}"

    # Validate profile name
    if ! validate_profile_name "$profile_name"; then
        print_error "Invalid profile name. Use only alphanumeric characters, dashes, and underscores."
        return 1
    fi

    # Check if profile already exists
    if profile_exists "$profile_name"; then
        print_error "Profile '$profile_name' already exists"
        return 2
    fi

    # Create profile directory
    local profile_dir
    profile_dir="$(get_profile_dir "$profile_name")"
    mkdir -p "$profile_dir"

    # Store API key in keychain
    if ! keychain_store "$profile_name" "$api_key"; then
        print_error "Failed to store API key in keychain"
        rm -rf "$profile_dir"
        return 3
    fi

    # Create configuration files
    create_profile_config "$profile_name" "$model" "$base_url"
    create_profile_metadata "$profile_name" "$description"

    return 0
}

# Switch to a profile
switch_profile() {
    local profile_name="$1"
    local skip_validation="${2:-false}"

    # Check if profile exists
    if ! profile_exists "$profile_name"; then
        print_error "Profile '$profile_name' does not exist"
        return 1
    fi

    # Get current active profile for rollback
    local previous_profile
    previous_profile=$(get_active_profile)

    # Retrieve API key from keychain
    local api_key
    api_key=$(keychain_retrieve "$profile_name")

    if [ $? -ne 0 ]; then
        print_error "Failed to retrieve API key from keychain for profile '$profile_name'"
        return 2
    fi

    # Get configuration values
    local model base_url
    model=$(get_config_value "$profile_name" "model")
    base_url=$(get_config_value "$profile_name" "base_url")

    # Validate configuration if not skipped
    if [ "$skip_validation" != "true" ]; then
        print_info "Validating profile configuration..."

        validate_profile_config "$api_key" "$base_url" "$model" "false"
        local validation_result=$?

        if [ $validation_result -ne 0 ]; then
            local error_msg
            error_msg=$(get_validation_error "$validation_result")
            print_error "Validation failed: $error_msg"

            # Don't apply the profile if validation fails
            return 3
        fi

        print_success "Profile validation passed"
    fi

    # Apply the profile
    if ! apply_profile "$profile_name" "$api_key"; then
        print_error "Failed to apply profile configuration"
        return 4
    fi

    # Set as active profile
    set_active_profile "$profile_name"

    return 0
}

# Delete a profile
remove_profile() {
    local profile_name="$1"

    # Check if profile exists
    if ! profile_exists "$profile_name"; then
        print_error "Profile '$profile_name' does not exist"
        return 1
    fi

    # Check if this is the active profile
    local active
    active=$(get_active_profile)
    if [ "$active" = "$profile_name" ]; then
        # Clear the active profile marker if deleting the active one
        rm -f "$ACTIVE_PROFILE_FILE"
        print_info "Clearing active profile marker..."
    fi

    # Delete API key from keychain
    keychain_delete "$profile_name"

    # Delete profile directory
    if ! delete_profile "$profile_name"; then
        print_error "Failed to delete profile directory"
        return 3
    fi

    return 0
}

# Rename a profile
rename_profile_with_keychain() {
    local old_name="$1"
    local new_name="$2"

    # Validate new profile name
    if ! validate_profile_name "$new_name"; then
        print_error "Invalid profile name. Use only alphanumeric characters, dashes, and underscores."
        return 1
    fi

    # Check if old profile exists
    if ! profile_exists "$old_name"; then
        print_error "Profile '$old_name' does not exist"
        return 2
    fi

    # Check if new name already exists
    if profile_exists "$new_name"; then
        print_error "Profile '$new_name' already exists"
        return 3
    fi

    # Retrieve API key from old profile
    local api_key
    api_key=$(keychain_retrieve "$old_name")

    if [ $? -ne 0 ]; then
        print_error "Failed to retrieve API key from keychain"
        return 4
    fi

    # Store API key under new name
    if ! keychain_store "$new_name" "$api_key"; then
        print_error "Failed to store API key under new name"
        return 5
    fi

    # Rename profile directory
    if ! rename_profile "$old_name" "$new_name"; then
        # Rollback keychain entry
        keychain_delete "$new_name"
        print_error "Failed to rename profile directory"
        return 6
    fi

    # Delete old keychain entry
    keychain_delete "$old_name"

    return 0
}

# Update profile model
update_profile_model() {
    local profile_name="$1"
    local new_model="$2"

    if ! profile_exists "$profile_name"; then
        print_error "Profile '$profile_name' does not exist"
        return 1
    fi

    # Update config
    if ! update_config_value "$profile_name" "model" "$new_model"; then
        print_error "Failed to update model in profile configuration"
        return 2
    fi

    # If this is the active profile, re-apply it
    local active
    active=$(get_active_profile)
    if [ "$active" = "$profile_name" ]; then
        local api_key
        api_key=$(keychain_retrieve "$profile_name")

        if [ $? -eq 0 ]; then
            apply_profile "$profile_name" "$api_key"
        fi
    fi

    return 0
}

# Get profile information
get_profile_info() {
    local profile_name="$1"

    if ! profile_exists "$profile_name"; then
        return 1
    fi

    # Get all info
    local model base_url created last_used description api_key_status

    model=$(get_config_value "$profile_name" "model")
    base_url=$(get_config_value "$profile_name" "base_url")
    created=$(get_metadata_value "$profile_name" "created")
    last_used=$(get_metadata_value "$profile_name" "last_used")
    description=$(get_metadata_value "$profile_name" "description")

    # Check if API key exists
    if keychain_exists "$profile_name"; then
        api_key_status="stored"
    else
        api_key_status="missing"
    fi

    # Output as JSON
    jq -n \
        --arg name "$profile_name" \
        --arg model "$model" \
        --arg base_url "$base_url" \
        --arg created "$created" \
        --arg last_used "$last_used" \
        --arg description "$description" \
        --arg api_key_status "$api_key_status" \
        '{
            name: $name,
            model: $model,
            base_url: $base_url,
            created: $created,
            last_used: $last_used,
            description: $description,
            api_key_status: $api_key_status
        }'
}
