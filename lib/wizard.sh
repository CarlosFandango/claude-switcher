#!/bin/bash
# Interactive Setup Wizard

# Run the setup wizard
run_setup_wizard() {
    local create_another="y"

    print_header "Welcome to Claude Switch Setup"

    print_info "This wizard will help you configure your first Claude profile."
    print_info "You can switch between different Claude API configurations easily."
    echo ""

    # Check if profiles already exist
    local existing_profiles
    existing_profiles=$(list_profiles)

    if [ -n "$existing_profiles" ]; then
        print_warning "Existing profiles found:"
        echo "$existing_profiles" | while read -r profile; do
            echo "  - $profile"
        done
        echo ""

        if ! prompt_confirm "Do you want to create a new profile?"; then
            return 0
        fi
    fi

    while [ "$create_another" = "y" ] || [ "$create_another" = "Y" ]; do
        if ! create_profile_interactive; then
            print_error "Failed to create profile. Please try again."
            if ! prompt_confirm "Do you want to retry?"; then
                return 1
            fi
            continue
        fi

        echo ""
        if prompt_confirm "Do you want to create another profile?" "n"; then
            create_another="y"
        else
            create_another="n"
        fi
    done

    print_header "Setup Complete!"
    print_success "Your profiles have been configured successfully."
    echo ""
    print_info "Use 'claude-switch list' to see all profiles"
    print_info "Use 'claude-switch switch <profile>' to change profiles"
    print_info "Use 'claude-switch status' to see your current configuration"
    echo ""
}

# Interactive profile creation
create_profile_interactive() {
    print_header "Create New Profile"

    # Step 1: Profile name
    local profile_name
    while true; do
        profile_name=$(prompt_input "Enter profile name (e.g., 'personal', 'work', 'dev')")

        if [ -z "$profile_name" ]; then
            print_warning "Profile name cannot be empty"
            continue
        fi

        if ! validate_profile_name "$profile_name"; then
            print_warning "Invalid profile name. Use only alphanumeric characters, dashes, and underscores."
            continue
        fi

        if profile_exists "$profile_name"; then
            print_warning "Profile '$profile_name' already exists"
            continue
        fi

        break
    done

    # Step 2: Description
    local description
    description=$(prompt_input "Enter profile description (optional)" "")

    # Step 3: Select API provider
    echo ""
    print_info "Select your API provider:"

    local provider_options=(
        "Anthropic (Direct API)"
        "Google Vertex AI"
        "AWS Bedrock"
        "Custom/Other (LiteLLM, self-hosted, etc.)"
    )

    local provider_choice
    provider_choice=$(select_from_menu "Select API provider:" "${provider_options[@]}")

    if [ $? -ne 0 ] || [ -z "$provider_choice" ]; then
        print_error "Provider selection cancelled"
        return 1
    fi

    # Step 3b: Set base URL based on provider
    local base_url
    case "$provider_choice" in
        "Anthropic (Direct API)")
            base_url="https://api.anthropic.com"
            print_success "Using Anthropic Direct API: $base_url"
            ;;

        "Google Vertex AI")
            local region
            region=$(prompt_input "Enter Vertex AI region (e.g., us-east5, europe-west1)" "us-east5")
            base_url="https://${region}-aiplatform.googleapis.com"
            print_success "Using Vertex AI: $base_url"
            ;;

        "AWS Bedrock")
            local region
            region=$(prompt_input "Enter AWS region (e.g., us-east-1, us-west-2)" "us-east-1")
            base_url="https://bedrock-runtime.${region}.amazonaws.com"
            print_success "Using AWS Bedrock: $base_url"
            ;;

        "Custom/Other (LiteLLM, self-hosted, etc.)")
            while true; do
                base_url=$(prompt_input "Enter custom base URL" "https://litellm.company.com")

                if ! validate_url "$base_url"; then
                    print_warning "Invalid URL format. Must start with http:// or https://"
                    continue
                fi

                # Test connectivity for custom URLs
                print_info "Testing connection to $base_url..."
                if test_api_connection "$base_url" 5; then
                    print_success "Connection successful"
                    break
                else
                    print_error "Cannot connect to $base_url"
                    if prompt_confirm "Do you want to try a different URL?"; then
                        continue
                    else
                        print_warning "Proceeding without connectivity test"
                        break
                    fi
                fi
            done
            ;;
    esac

    # Step 4: API key
    local api_key
    while true; do
        api_key=$(prompt_secure "Enter your API key")

        if [ -z "$api_key" ]; then
            print_warning "API key cannot be empty"
            continue
        fi

        if ! validate_api_key_format "$api_key"; then
            print_warning "API key format appears invalid (expected to start with: sk-...)"
            if ! prompt_confirm "Do you want to use this key anyway?"; then
                continue
            fi
        fi

        # Test API key
        print_info "Validating API key..."
        if validate_api_key_live "$api_key" "$base_url" 10; then
            print_success "API key is valid"
            break
        else
            print_error "API key validation failed"
            if prompt_confirm "Do you want to try a different API key?"; then
                continue
            else
                print_warning "Proceeding with unvalidated API key"
                break
            fi
        fi
    done

    # Step 5: Select model
    local model

    # Check if this is a service that manages model selection internally
    if [[ "$base_url" == *"api.anthropic.com"* ]] || \
       [[ "$base_url" == *"aiplatform.googleapis.com"* ]] || \
       [[ "$base_url" == *"bedrock-runtime"* ]]; then

        if [[ "$base_url" == *"api.anthropic.com"* ]]; then
            print_info "Anthropic API detected - model selection handled by Claude Code"
        elif [[ "$base_url" == *"aiplatform.googleapis.com"* ]]; then
            print_info "Google Vertex AI detected - model selection handled by Vertex AI"
        elif [[ "$base_url" == *"bedrock-runtime"* ]]; then
            print_info "AWS Bedrock detected - model selection handled by Bedrock"
        fi

        model="claude-sonnet-4-20250514"  # Placeholder - service will manage actual model
    else
        # For LiteLLM and custom proxies, fetch and select model
        print_info "Fetching available models..."

        local models
        models=$(get_model_ids "$api_key" "$base_url" 2>/dev/null)

        if [ -n "$models" ] && [ "$(echo "$models" | wc -l)" -gt 0 ]; then
            print_success "Found $(echo "$models" | wc -l) available models"
            echo ""

            model=$(select_model_interactive "$api_key" "$base_url")
            if [ $? -ne 0 ]; then
                print_warning "Failed to select model interactively"
                model=$(prompt_input "Enter model name manually" "claude-sonnet-4-20250514")
            fi
        else
            print_warning "Could not fetch models from API"
            model=$(prompt_input "Enter model name manually" "claude-sonnet-4-20250514")
        fi
    fi

    # Step 6: Confirm and create
    echo ""
    print_header "Profile Summary"
    print_info "Name:        $profile_name"
    print_info "Description: ${description:-N/A}"
    print_info "Base URL:    $base_url"
    print_info "Model:       $model"
    print_info "API Key:     ${api_key:0:20}..."
    echo ""

    if ! prompt_confirm "Create this profile?"; then
        print_warning "Profile creation cancelled"
        return 1
    fi

    # Create the profile
    if create_profile "$profile_name" "$api_key" "$model" "$base_url" "$description"; then
        print_success "Profile '$profile_name' created successfully!"

        # Offer to switch to it
        if prompt_confirm "Do you want to switch to this profile now?"; then
            if switch_profile "$profile_name" "true"; then
                print_success "Switched to profile '$profile_name'"
            else
                print_error "Failed to switch to profile"
                return 1
            fi
        fi

        return 0
    else
        print_error "Failed to create profile"
        return 1
    fi
}

# Quick setup for common scenarios
quick_setup() {
    local scenario="$1"

    case "$scenario" in
        "litellm")
            print_header "Quick Setup: LiteLLM Profile"

            local profile_name="litellm"
            local description="LiteLLM proxy profile"
            local base_url="https://litellm.example.com"

            # Check if already exists
            if profile_exists "$profile_name"; then
                print_error "Profile 'litellm' already exists"
                return 1
            fi

            # Just ask for API key
            local api_key
            api_key=$(prompt_secure "Enter your LiteLLM API key")

            print_info "Testing API key..."
            if ! validate_api_key_live "$api_key" "$base_url"; then
                print_error "API key validation failed"
                return 1
            fi

            # Fetch first available model
            local model
            model=$(get_model_ids "$api_key" "$base_url" | head -n1)

            if [ -z "$model" ]; then
                model="claude-sonnet-4-20250514"
            fi

            # Create profile
            if create_profile "$profile_name" "$api_key" "$model" "$base_url" "$description"; then
                print_success "LiteLLM profile created successfully!"
                switch_profile "$profile_name" "true"
                return 0
            fi

            return 1
            ;;

        *)
            print_error "Unknown quick setup scenario: $scenario"
            return 1
            ;;
    esac
}
