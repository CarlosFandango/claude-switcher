#!/bin/bash
# Shell Integration for claude-switch

# Get the active profile name for prompt display
claude_switch_prompt() {
    local active_profile_file="$HOME/.claude/active-profile"

    if [ -f "$active_profile_file" ]; then
        cat "$active_profile_file"
    fi
}

# Get active profile with icon for prompt
claude_switch_prompt_decorated() {
    local profile
    profile=$(claude_switch_prompt)

    if [ -n "$profile" ]; then
        echo "󰧑 $profile"
    fi
}

# ZSH prompt function (returns empty if no profile active)
claude_switch_zsh_prompt() {
    local profile
    profile=$(claude_switch_prompt)

    if [ -n "$profile" ]; then
        echo "%F{cyan}󰧑 $profile%f"
    fi
}

# Export functions for shell use
export -f claude_switch_prompt 2>/dev/null || true
export -f claude_switch_prompt_decorated 2>/dev/null || true
export -f claude_switch_zsh_prompt 2>/dev/null || true
