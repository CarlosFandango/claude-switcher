#!/bin/bash
# UI Components and User Interface Functions

# Color definitions
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Print colored message
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Print success message
print_success() {
    print_message "$GREEN" "✓ $1"
}

# Print error message
print_error() {
    print_message "$RED" "✗ $1"
}

# Print warning message
print_warning() {
    print_message "$YELLOW" "⚠ $1"
}

# Print info message
print_info() {
    print_message "$BLUE" "ℹ $1"
}

# Print section header
print_header() {
    echo ""
    print_message "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$CYAN" "  $1"
    print_message "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Print a spinner while waiting
show_spinner() {
    local pid=$1
    local message="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${BLUE}${spin:$i:1}${NC} %s" "$message"
        sleep 0.1
    done
    printf "\r"
}

# Prompt for user input
prompt_input() {
    local prompt="$1"
    local default="$2"
    local response

    if [ -n "$default" ]; then
        printf "${YELLOW}%s [%s]: ${NC}" "$prompt" "$default" >&2
    else
        printf "${YELLOW}%s: ${NC}" "$prompt" >&2
    fi

    read -r response
    echo "${response:-$default}"
}

# Prompt for secure input (hidden)
prompt_secure() {
    local prompt="$1"
    local response

    printf "${YELLOW}%s: ${NC}" "$prompt" >&2
    read -s -r response
    echo "" >&2 # New line after hidden input
    echo "$response"
}

# Prompt for yes/no confirmation
prompt_confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    if [ "$default" = "y" ]; then
        printf "${YELLOW}%s [Y/n]: ${NC}" "$prompt" >&2
    else
        printf "${YELLOW}%s [y/N]: ${NC}" "$prompt" >&2
    fi

    read -r response
    response="${response:-$default}"

    [[ "$response" =~ ^[Yy]$ ]]
}

# Display a table header
print_table_header() {
    local col1="$1"
    local col2="$2"
    local col3="$3"

    printf "${CYAN}%-20s %-30s %-25s${NC}\n" "$col1" "$col2" "$col3"
    printf "%-20s %-30s %-25s\n" "--------------------" "------------------------------" "-------------------------"
}

# Display a table row
print_table_row() {
    local col1="$1"
    local col2="$2"
    local col3="$3"
    local active="${4:-false}"

    if [ "$active" = "true" ]; then
        printf "${GREEN}%-20s %-30s %-25s${NC}\n" "$col1" "$col2" "$col3"
    else
        printf "%-20s %-30s %-25s\n" "$col1" "$col2" "$col3"
    fi
}

# Display progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r${BLUE}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %d%%${NC}" "$percentage"
}

# Clear progress bar
clear_progress() {
    printf "\r%80s\r" " "
}
