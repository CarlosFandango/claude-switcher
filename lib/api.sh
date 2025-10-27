#!/bin/bash
# LiteLLM API Interaction Functions

# Fetch available models from API endpoint
fetch_models() {
    local api_key="$1"
    local base_url="$2"
    local timeout="${3:-10}"

    # Check if this is Anthropic's direct API
    if [[ "$base_url" == *"api.anthropic.com"* ]]; then
        # Anthropic API doesn't have /v1/models endpoint
        # Model selection is handled by Claude Code directly
        return 1
    fi

    # For LiteLLM and other proxies, fetch from /v1/models endpoint
    local response http_code

    # Try x-api-key header first
    response=$(curl -s -w "\n%{http_code}" -m "$timeout" \
        -H "x-api-key: $api_key" \
        -H "Content-Type: application/json" \
        "${base_url}/v1/models" 2>/dev/null)

    http_code=$(echo "$response" | tail -n 1)

    # If x-api-key failed with 401/403, try Authorization Bearer
    if [[ "$http_code" =~ ^(401|403)$ ]]; then
        response=$(curl -s -w "\n%{http_code}" -m "$timeout" \
            -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            "${base_url}/v1/models" 2>/dev/null)

        http_code=$(echo "$response" | tail -n 1)
    fi

    # Remove HTTP code from response
    local body
    body=$(echo "$response" | sed '$d')

    # Check if response is valid JSON
    if ! echo "$body" | jq -e '.data' > /dev/null 2>&1; then
        return 1
    fi

    echo "$body"
}

# Get list of model IDs
get_model_ids() {
    local api_key="$1"
    local base_url="$2"

    local response
    response=$(fetch_models "$api_key" "$base_url")

    if [ $? -ne 0 ]; then
        return 1
    fi

    # Extract model IDs
    echo "$response" | jq -r '.data[].id' | sort
}

# Get model details by ID
get_model_details() {
    local model_id="$1"
    local api_key="$2"
    local base_url="$3"

    local response
    response=$(fetch_models "$api_key" "$base_url")

    if [ $? -ne 0 ]; then
        return 1
    fi

    # Get specific model details
    echo "$response" | jq --arg id "$model_id" '.data[] | select(.id == $id)'
}

# Test API health
test_api_health() {
    local api_key="$1"
    local base_url="$2"
    local timeout="${3:-5}"

    # Try to fetch models as a health check
    if fetch_models "$api_key" "$base_url" "$timeout" > /dev/null 2>&1; then
        return 0
    fi

    return 1
}

# Format model list for display
format_model_list() {
    local models="$1"
    local current_model="$2"

    echo "$models" | while IFS= read -r model; do
        if [ "$model" = "$current_model" ]; then
            echo "  → $model (current)"
        else
            echo "    $model"
        fi
    done
}

# Interactive model selection
select_model_interactive() {
    local api_key="$1"
    local base_url="$2"
    local current_model="${3:-}"

    # Fetch available models
    local models
    models=$(get_model_ids "$api_key" "$base_url")

    if [ $? -ne 0 ] || [ -z "$models" ]; then
        print_error "Failed to fetch models from API"
        return 1
    fi

    # Convert to array (bash 3.2 compatible)
    local model_array=()
    local i=0
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            model_array[$i]="$line"
            ((i++))
        fi
    done <<< "$models"

    # Display models (output to stderr since this function returns a value)
    print_info "Available models:" >&2
    echo "" >&2

    local idx=1
    for model in "${model_array[@]}"; do
        if [ "$model" = "$current_model" ]; then
            printf "${GREEN}  %2d) %s (current)${NC}\n" "$idx" "$model" >&2
        else
            printf "  %2d) %s\n" "$idx" "$model" >&2
        fi
        ((idx++))
    done

    echo "" >&2

    # Prompt for selection
    local selection
    local array_size=${#model_array[@]}
    while true; do
        printf "Select model number (1-$array_size): " >&2
        read -r selection

        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$array_size" ]; then
            echo "${model_array[$((selection-1))]}"
            return 0
        else
            print_warning "Invalid selection. Please enter a number between 1 and $array_size"
        fi
    done
}

# Check API version compatibility
check_api_version() {
    local base_url="$1"

    # Try to get version info (if endpoint exists)
    local version_response
    version_response=$(curl -s "${base_url}/version" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$version_response" ]; then
        echo "$version_response" | jq -r '.version // "unknown"'
    else
        echo "unknown"
    fi
}
