# Shell Integration for claude-switch

Display your active Claude profile in your shell prompt!

## ZSH Integration

### Option 1: Spaceship Prompt

If you use [Spaceship Prompt](https://spaceship-prompt.sh/), this is the recommended integration:

**Step 1:** Create a custom section file:

```bash
# Create the file
cat > ~/.oh-my-zsh/custom/claude_profile.zsh << 'EOF'
# Claude Switch profile section for Spaceship prompt

spaceship_claude_profile() {
  # If not in a Spaceship prompt, return
  [[ $SPACESHIP_VERSION ]] || return

  local profile_file="$HOME/.claude/active-profile"

  # Check if profile exists
  [[ -f "$profile_file" ]] || return

  local profile=$(cat "$profile_file")

  # Display the profile
  spaceship::section \
    --color cyan \
    --prefix '' \
    --suffix ' ' \
    --symbol '󰧑 ' \
    "$profile"
}
EOF
```

**Step 2:** Add to your `~/.zshrc` (before Oh My Zsh is loaded):

```bash
# Spaceship prompt configuration - add claude_profile to right prompt
SPACESHIP_RPROMPT_ORDER=(
  claude_profile  # Claude Switch profile
  time            # Time stamps section
  exec_time       # Execution time
)
```

**Step 3:** Reload your shell:

```bash
exec zsh
```

Your prompt will now show `󰧑 work` or `󰧑 personal` on the right side!

### Option 2: Starship Prompt

If you use [Starship](https://starship.rs/), add this to your `~/.config/starship.toml`:

```toml
[custom.claude]
command = "cat ~/.claude/active-profile 2>/dev/null"
when = "test -f ~/.claude/active-profile"
format = "[$symbol$output]($style) "
symbol = "󰧑 "
style = "cyan"
```

### Option 3: Oh My Zsh Theme

Add to your `~/.zshrc` (before loading Oh My Zsh):

```bash
# Claude Switch prompt integration
claude_prompt() {
    if [ -f "$HOME/.claude/active-profile" ]; then
        echo "%F{cyan}󰧑 $(cat $HOME/.claude/active-profile)%f "
    fi
}

# Add to your theme's RPROMPT or PROMPT
# Example for RPROMPT:
RPROMPT='$(claude_prompt)'

# Or add to existing RPROMPT:
# RPROMPT='$(claude_prompt)${RPROMPT}'
```

### Option 4: Custom ZSH Prompt

Add to your `~/.zshrc`:

```bash
# Claude Switch prompt function
claude_prompt() {
    if [ -f "$HOME/.claude/active-profile" ]; then
        echo "%F{cyan}󰧑 $(cat $HOME/.claude/active-profile)%f "
    fi
}

# Add to your prompt (example with a simple prompt)
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f %F{blue}%~%f $(claude_prompt)
%# '
```

### Option 5: Using Powerlevel10k

If you use Powerlevel10k, add to your `~/.p10k.zsh`:

```bash
# Find the POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS array and add:
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # ... your existing elements ...
    claude_profile
    # ... more elements ...
)

# Then add this configuration:
function prompt_claude_profile() {
    local profile
    if [ -f "$HOME/.claude/active-profile" ]; then
        profile=$(cat "$HOME/.claude/active-profile")
        p10k segment -f cyan -i '󰧑' -t " $profile"
    fi
}
```

## Bash Integration

Add to your `~/.bashrc`:

```bash
# Claude Switch prompt function
claude_prompt() {
    if [ -f "$HOME/.claude/active-profile" ]; then
        echo -e "\\[\\033[36m\\]󰧑 $(cat $HOME/.claude/active-profile)\\[\\033[0m\\] "
    fi
}

# Add to PS1
PS1='\\u@\\h \\w $(claude_prompt)\\$ '
```

## Testing

After adding the integration:

1. Reload your shell configuration:
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

2. Switch to a profile:
   ```bash
   claude-switch switch work
   ```

3. Your prompt should now show: `󰧑 work`

4. Switch to another profile to see it update:
   ```bash
   claude-switch switch personal
   ```

## Custom Styling

You can customize the appearance by modifying:

- **Icon**: Change `󰧑` to any Nerd Font icon you prefer
  - ``: Claude icon
  - ``: Brain/AI icon
  - `󰚩`: Settings icon
  - ``: Profile icon

- **Color**: Change the color code
  - `%F{cyan}` - Cyan (default)
  - `%F{blue}` - Blue
  - `%F{magenta}` - Magenta
  - `%F{yellow}` - Yellow
  - `%F{green}` - Green

## Troubleshooting

### Icon not displaying
Install a Nerd Font:
```bash
brew tap homebrew/cask-fonts
brew install --cask font-meslo-lg-nerd-font
```

Then configure your terminal to use "MesloLG Nerd Font".

### Prompt not updating
The prompt reads from `~/.claude/active-profile` file. Make sure:
1. The file exists: `ls -la ~/.claude/active-profile`
2. It contains your profile name: `cat ~/.claude/active-profile`
3. Your prompt function uses `PROMPT_SUBST` (ZSH) or command substitution

### Profile shows but is outdated
The prompt is evaluated each time. If it's showing an old profile:
```bash
# Check what's in the file
cat ~/.claude/active-profile

# Check actual settings
claude-switch status
```
