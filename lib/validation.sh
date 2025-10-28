#!/bin/bash
# Validation Functions

# Validate API key format
validate_api_key_format() {
    local api_key="$1"

    # Check if empty
    if [ -z "$api_key" ]; then
        return 1
    fi

    # Check if starts with expected prefix (relaxed to accept any sk- prefix)
    if [[ ! "$api_key" =~ ^sk- ]]; then
        return 1
    fi

    # Basic length check (API keys are typically long, but relaxed for different formats)
    if [ ${#api_key} -lt 20 ]; then
        return 1
    fi

    return 0
}

# Validate URL format
validate_url() {
    local url="$1"

    # Check if empty
    if [ -z "$url" ]; then
        return 1
    fi

    # Check if starts with http:// or https://
    if [[ ! "$url" =~ ^https?:// ]]; then
        return 1
    fi

    return 0
}

# Validate model name format
validate_model_name() {
    local model="$1"

    # Check if empty
    if [ -z "$model" ]; then
        return 1
    fi

    # Model names typically contain alphanumeric, dash, and dot
    if [[ ! "$model" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        return 1
    fi

    return 0
}

# Test API endpoint connectivity (quick check)
test_api_connection() {
    local base_url="$1"
    local timeout="${2:-5}"

    # Try to reach the base URL or models endpoint with a simple GET
    # Some APIs don't support HEAD requests properly
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -m "$timeout" "${base_url}/v1/models" 2>/dev/null)

    # Accept any 2xx, 3xx, or 401 (means endpoint exists but needs auth)
    if [[ "$http_code" =~ ^[23] ]] || [ "$http_code" = "401" ]; then
        return 0
    fi

    return 1
}

# Validate API key with live API call
validate_api_key_live() {
    local api_key="$1"
    local base_url="$2"
    local timeout="${3:-5}"

    # Check if this is Anthropic's direct API, Vertex AI, or AWS Bedrock
    # These don't have /v1/models endpoint like LiteLLM
    if [[ "$base_url" == *"api.anthropic.com"* ]] || \
       [[ "$base_url" == *"aiplatform.googleapis.com"* ]] || \
       [[ "$base_url" == *"bedrock-runtime"* ]]; then
        # These services don't have /v1/models endpoint
        # The key will be validated when actually used
        return 0
    fi

    # For LiteLLM and other proxies, test /v1/models endpoint
    local response http_code body

    # Try x-api-key header first
    response=$(curl -s -w "\n%{http_code}" -m "$timeout" \
        -H "x-api-key: $api_key" \
        -H "Content-Type: application/json" \
        "${base_url}/v1/models" 2>/dev/null)

    # Extract HTTP code (last line)
    http_code=$(echo "$response" | tail -n 1)

    # If x-api-key failed with 401/403, try Authorization Bearer
    if [[ "$http_code" =~ ^(401|403)$ ]]; then
        response=$(curl -s -w "\n%{http_code}" -m "$timeout" \
            -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            "${base_url}/v1/models" 2>/dev/null)

        http_code=$(echo "$response" | tail -n 1)
    fi

    # Extract body (all but last line) - compatible with macOS
    body=$(echo "$response" | sed '$d')

    # Check if request was successful
    if [ "$http_code" != "200" ]; then
        return 1
    fi

    # Check if response is valid JSON with data array
    if ! echo "$body" | jq -e '.data' > /dev/null 2>&1; then
        return 1
    fi

    return 0
}

# Check if model exists in available models
validate_model_exists() {
    local model="$1"
    local api_key="$2"
    local base_url="$3"
    local timeout="${4:-5}"

    # Get available models - try x-api-key first
    local response http_code
    response=$(curl -s -w "\n%{http_code}" -m "$timeout" \
        -H "x-api-key: $api_key" \
        -H "Content-Type: application/json" \
        "${base_url}/v1/models" 2>/dev/null)

    http_code=$(echo "$response" | tail -n 1)

    # If x-api-key failed, try Authorization Bearer
    if [[ "$http_code" =~ ^(401|403)$ ]]; then
        response=$(curl -s -w "\n%{http_code}" -m "$timeout" \
            -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            "${base_url}/v1/models" 2>/dev/null)
    fi

    # Remove HTTP code
    local body
    body=$(echo "$response" | sed '$d')

    # Check if model exists in the list
    if echo "$body" | jq -e --arg model "$model" '.data[] | select(.id == $model)' > /dev/null 2>&1; then
        return 0
    fi

    return 1
}

# Get validation error message
get_validation_error() {
    local error_code="$1"

    case "$error_code" in
        1)
            echo "API key format is invalid. Expected to start with: sk-..."
            ;;
        2)
            echo "URL format is invalid. Expected format: https://..."
            ;;
        3)
            echo "Model name format is invalid"
            ;;
        4)
            echo "Cannot connect to API endpoint (timeout or unreachable)"
            ;;
        5)
            echo "API key authentication failed (401 or invalid response)"
            ;;
        6)
            echo "Model does not exist in available models list"
            ;;
        *)
            echo "Unknown validation error"
            ;;
    esac
}

# Comprehensive validation of profile configuration
validate_profile_config() {
    local api_key="$1"
    local base_url="$2"
    local model="$3"
    local skip_live="${4:-false}"

    # Validate API key format
    if ! validate_api_key_format "$api_key"; then
        return 1
    fi

    # Validate URL format
    if ! validate_url "$base_url"; then
        return 2
    fi

    # Validate model name format
    if ! validate_model_name "$model"; then
        return 3
    fi

    # Skip live validation if requested
    if [ "$skip_live" = "true" ]; then
        return 0
    fi

    # Test API connection
    if ! test_api_connection "$base_url"; then
        return 4
    fi

    # Validate API key with live call
    if ! validate_api_key_live "$api_key" "$base_url"; then
        return 5
    fi

    # Validate model exists (skip for Anthropic, Vertex AI, AWS Bedrock)
    if [[ "$base_url" != *"api.anthropic.com"* ]] && \
       [[ "$base_url" != *"aiplatform.googleapis.com"* ]] && \
       [[ "$base_url" != *"bedrock-runtime"* ]]; then
        if ! validate_model_exists "$model" "$api_key" "$base_url"; then
            return 6
        fi
    fi

    return 0
}
