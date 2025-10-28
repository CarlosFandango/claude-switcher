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

# Interactive menu with arrow key navigation
# Usage: selected=$(select_from_menu "Prompt" "${options[@]}")
# Returns: Selected option or empty string if cancelled
select_from_menu() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=0
    local num_options=${#options[@]}

    # If no options, return empty
    if [ "$num_options" -eq 0 ]; then
        return 1
    fi

    # Hide cursor
    tput civis >&2

    # Function to draw menu
    draw_menu() {
        # Clear from current line down
        tput ed >&2

        # Print prompt
        printf "${CYAN}%s${NC}\n" "$prompt" >&2
        printf "${CYAN}%s${NC}\n" "Use ↑/↓ to navigate, Enter to select, q to cancel" >&2
        echo "" >&2

        # Print options
        for i in "${!options[@]}"; do
            if [ "$i" -eq "$selected" ]; then
                printf "${GREEN}❯ %s${NC}\n" "${options[$i]}" >&2
            else
                printf "  %s\n" "${options[$i]}" >&2
            fi
        done
    }

    # Initial draw
    draw_menu

    # Read user input
    while true; do
        # Save cursor position
        local lines_to_move=$((num_options + 3))

        # Read single character
        read -rsn1 key

        # Handle escape sequences for arrow keys
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
        fi

        # Move cursor back up to redraw
        tput cuu $lines_to_move >&2

        case "$key" in
            '[A'|'k') # Up arrow or k
                ((selected--))
                if [ "$selected" -lt 0 ]; then
                    selected=$((num_options - 1))
                fi
                ;;
            '[B'|'j') # Down arrow or j
                ((selected++))
                if [ "$selected" -ge "$num_options" ]; then
                    selected=0
                fi
                ;;
            '') # Enter
                # Show cursor
                tput cnorm >&2
                # Clear menu
                tput ed >&2
                echo "${options[$selected]}"
                return 0
                ;;
            'q'|'Q') # Quit
                # Show cursor
                tput cnorm >&2
                # Clear menu
                tput ed >&2
                return 1
                ;;
        esac

        # Redraw menu
        draw_menu
    done
}
