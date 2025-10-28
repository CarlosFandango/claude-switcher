#!/bin/bash
# Uninstall script for claude-switch

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

prompt_confirm() {
    local prompt="$1"
    local response

    printf "${YELLOW}%s [y/N]: ${NC}" "$prompt"
    read -r response

    [[ "$response" =~ ^[Yy]$ ]]
}

print_header "Claude Switch Uninstaller"

echo "This will remove claude-switch from your system."
echo ""

# Check if installed
if [ ! -f "/usr/local/bin/claude-switch" ]; then
    print_error "claude-switch is not installed in /usr/local/bin"
    exit 1
fi

# Show what will be removed
print_info "The following will be removed:"
echo "  - /usr/local/bin/claude-switch"
echo "  - /usr/local/lib/claude-switch/"
echo ""

# Ask about user data
REMOVE_DATA=false
if [ -d "$HOME/.claude/profiles" ] || [ -f "$HOME/.claude/settings.json" ]; then
    print_warning "User data found:"

    if [ -d "$HOME/.claude/profiles" ]; then
        local profile_count
        profile_count=$(find "$HOME/.claude/profiles" -maxdepth 1 -type d | wc -l | tr -d ' ')
        profile_count=$((profile_count - 1))  # Exclude the profiles directory itself
        echo "  - $profile_count profile(s) in ~/.claude/profiles/"
    fi

    if [ -f "$HOME/.claude/settings.json" ]; then
        echo "  - Active settings in ~/.claude/settings.json"
    fi

    if [ -f "$HOME/.claude/active-profile" ]; then
        local active
        active=$(cat "$HOME/.claude/active-profile" 2>/dev/null)
        echo "  - Active profile: $active"
    fi

    echo ""
    print_warning "This will also remove API keys from macOS Keychain"
    echo ""

    if prompt_confirm "Do you want to remove all user data and profiles?"; then
        REMOVE_DATA=true
    else
        print_info "User data will be preserved"
    fi
fi

echo ""
if ! prompt_confirm "Continue with uninstallation?"; then
    print_info "Uninstallation cancelled"
    exit 0
fi

echo ""
print_header "Uninstalling"

# Remove binary
if [ -f "/usr/local/bin/claude-switch" ]; then
    print_info "Removing claude-switch binary..."
    sudo rm -f /usr/local/bin/claude-switch
    print_success "Binary removed"
fi

# Remove library files
if [ -d "/usr/local/lib/claude-switch" ]; then
    print_info "Removing library files..."
    sudo rm -rf /usr/local/lib/claude-switch
    print_success "Library files removed"
fi

# Remove user data if requested
if [ "$REMOVE_DATA" = true ]; then
    print_info "Removing user data..."

    # Remove keychain entries
    if [ -d "$HOME/.claude/profiles" ]; then
        for profile_dir in "$HOME/.claude/profiles"/*; do
            if [ -d "$profile_dir" ]; then
                profile_name=$(basename "$profile_dir")
                print_info "  Removing keychain entry for: $profile_name"
                security delete-generic-password -s "com.claude-switch.${profile_name}" -a "api-key" 2>/dev/null || true
            fi
        done
    fi

    # Remove profiles
    if [ -d "$HOME/.claude/profiles" ]; then
        rm -rf "$HOME/.claude/profiles"
        print_success "Profiles removed"
    fi

    # Remove settings
    if [ -f "$HOME/.claude/settings.json" ]; then
        rm -f "$HOME/.claude/settings.json"
        print_success "Settings removed"
    fi

    # Remove active profile marker
    if [ -f "$HOME/.claude/active-profile" ]; then
        rm -f "$HOME/.claude/active-profile"
        print_success "Active profile marker removed"
    fi

    # Remove shell integration (if user created it)
    if [ -f "$HOME/.oh-my-zsh/custom/claude_profile.zsh" ]; then
        if prompt_confirm "Remove shell integration (~/.oh-my-zsh/custom/claude_profile.zsh)?"; then
            rm -f "$HOME/.oh-my-zsh/custom/claude_profile.zsh"
            print_success "Shell integration removed"
        fi
    fi
fi

echo ""
print_header "Uninstallation Complete"

if [ "$REMOVE_DATA" = true ]; then
    print_success "claude-switch has been completely removed from your system"
else
    print_success "claude-switch has been uninstalled"
    print_info "User data preserved in ~/.claude/"
    echo ""
    print_info "To manually remove user data later:"
    echo "  rm -rf ~/.claude/profiles"
    echo "  rm -f ~/.claude/settings.json"
    echo "  rm -f ~/.claude/active-profile"
    echo "  security delete-generic-password -s com.claude-switch.<profile> -a api-key"
fi

echo ""
print_info "Thank you for using claude-switch!"
echo ""
