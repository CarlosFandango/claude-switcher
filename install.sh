#!/bin/bash

# AI Configuration Switcher - Installation Script
# Automates the complete setup process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/bin"
COMMANDS_DIR="$HOME/.claude/commands"
SCRIPT_NAME="claude-switch"

echo -e "${BLUE}=== AI Configuration Switcher Installation ===${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root${NC}"
   echo "Please run as your normal user. The script will prompt for sudo when needed."
   exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check for Claude Code CLI
check_claude_cli() {
    echo -e "${YELLOW}Checking for AI CLI...${NC}"
    
    # Check for claude command
    if command_exists claude; then
        echo -e "${GREEN}✓ AI CLI found${NC}"
        return 0
    fi
    
    # Check for claude-code command
    if command_exists claude-code; then
        echo -e "${GREEN}✓ AI CLI found (claude-code)${NC}"
        return 0
    fi
    
    # Check if ~/.claude directory exists (indicates previous installation)
    if [ -d "$HOME/.claude" ]; then
        echo -e "${YELLOW}AI CLI configuration directory found, but command not in PATH${NC}"
        echo -e "${YELLOW}You may need to restart your terminal or check your PATH${NC}"
        return 0
    fi
    
    # AI CLI not found
    echo -e "${RED}✗ AI CLI not found${NC}"
    echo ""
    echo -e "${YELLOW}This tool requires an AI CLI to be installed first.${NC}"
    echo ""
    echo -e "${BLUE}To install AI CLI:${NC}"
    echo "1. Visit: https://docs.anthropic.com/en/docs/claude-code/quickstart"
    echo "2. Follow the installation instructions for your platform"
    echo "3. Run the AI CLI at least once to create initial configuration"
    echo "4. Then re-run this installation script"
    echo ""
    echo -e "${YELLOW}Quick install options:${NC}"
    echo "  macOS: curl -fsSL https://claude.ai/install.sh | sh"
    echo "  Other: See documentation link above"
    echo ""
    
    read -p "Would you like to continue anyway? (y/N): " continue_anyway
    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        echo "Installation cancelled. Please install AI CLI first."
        exit 1
    fi
    
    echo -e "${YELLOW}Continuing without AI CLI verification...${NC}"
    # Create claude directory structure manually
    mkdir -p "$COMMANDS_DIR"
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    local missing_deps=()
    
    if ! command_exists curl; then
        missing_deps+=("curl")
    fi
    
    if ! command_exists jq; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ All dependencies found${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Missing dependencies: ${missing_deps[*]}${NC}"
    
    # Detect package manager and install
    if command_exists brew; then
        echo -e "${YELLOW}Installing dependencies via Homebrew...${NC}"
        for dep in "${missing_deps[@]}"; do
            brew install "$dep"
        done
    elif command_exists apt-get; then
        echo -e "${YELLOW}Installing dependencies via apt...${NC}"
        sudo apt-get update
        sudo apt-get install -y "${missing_deps[@]}"
    elif command_exists yum; then
        echo -e "${YELLOW}Installing dependencies via yum...${NC}"
        sudo yum install -y "${missing_deps[@]}"
    elif command_exists dnf; then
        echo -e "${YELLOW}Installing dependencies via dnf...${NC}"
        sudo dnf install -y "${missing_deps[@]}"
    else
        echo -e "${RED}Unable to detect package manager. Please install manually:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
    
    echo -e "${GREEN}✓ Dependencies installed${NC}"
}

# Function to install main script
install_main_script() {
    echo -e "${YELLOW}Installing main script...${NC}"
    
    if [ ! -f "$SCRIPT_NAME" ]; then
        echo -e "${RED}Error: $SCRIPT_NAME not found in current directory${NC}"
        echo "Please run this script from the directory containing $SCRIPT_NAME"
        exit 1
    fi
    
    # Make executable
    chmod +x "$SCRIPT_NAME"
    
    # Copy to system path
    echo "Installing to $INSTALL_DIR (requires sudo)..."
    sudo cp "$SCRIPT_NAME" "$INSTALL_DIR/"
    
    # Verify installation
    if command_exists "$SCRIPT_NAME"; then
        echo -e "${GREEN}✓ Main script installed successfully${NC}"
    else
        echo -e "${RED}✗ Installation failed - script not found in PATH${NC}"
        exit 1
    fi
}

# Function to install AI CLI integration
install_ai_integration() {
    echo -e "${YELLOW}Installing AI CLI integration...${NC}"
    
    if [ ! -f "litellm.md" ]; then
        echo -e "${YELLOW}Warning: litellm.md not found, skipping AI CLI integration${NC}"
        return 0
    fi
    
    # Create commands directory if it doesn't exist
    mkdir -p "$COMMANDS_DIR"
    
    # Copy slash command
    cp "litellm.md" "$COMMANDS_DIR/"
    
    echo -e "${GREEN}✓ AI CLI integration installed${NC}"
    echo -e "  Slash command available: ${BLUE}/litellm${NC}"
}

# Function to run initial setup
run_initial_setup() {
    echo -e "${YELLOW}Running initial setup...${NC}"
    
    # Test basic functionality
    echo "Testing installation..."
    if ! "$SCRIPT_NAME" help >/dev/null 2>&1; then
        echo -e "${RED}✗ Installation test failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Installation test passed${NC}"
    
    # Prompt for configuration setup
    echo ""
    echo -e "${BLUE}Configuration Setup${NC}"
    echo "Would you like to set up your work profile now? (y/N)"
    read -r setup_work
    
    if [[ $setup_work =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Setting up work profile...${NC}"
        "$SCRIPT_NAME" work
    else
        echo -e "${YELLOW}You can set up profiles later using:${NC}"
        echo "  $SCRIPT_NAME work    # Set up work/LiteLLM profile"
        echo "  $SCRIPT_NAME personal # Switch to personal profile"
    fi
}

# Function to show completion message
show_completion() {
    echo ""
    echo -e "${GREEN}=== Installation Complete! ===${NC}"
    echo ""
    echo -e "${BLUE}Quick Start:${NC}"
    echo "  $SCRIPT_NAME help           # Show all commands"
    echo "  $SCRIPT_NAME status         # Check current configuration"
    echo "  $SCRIPT_NAME work           # Switch to work profile"
    echo "  $SCRIPT_NAME model list     # List available models"
    echo ""
    echo -e "${BLUE}AI CLI Integration:${NC}"
    echo "  /litellm list              # List models in AI CLI"
    echo "  /litellm set <model>       # Switch model in AI CLI"
    echo ""
    echo -e "${YELLOW}For detailed documentation, see README.md${NC}"
}

# Main installation flow
main() {
    # Check for AI CLI first
    check_claude_cli
    
    # Check if already installed
    if command_exists "$SCRIPT_NAME" && [ -f "$COMMANDS_DIR/litellm.md" ]; then
        echo -e "${YELLOW}AI Configuration Switcher appears to already be installed.${NC}"
        echo "Would you like to reinstall/update? (y/N)"
        read -r reinstall
        if [[ ! $reinstall =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
    
    install_dependencies
    install_main_script
    install_ai_integration
    run_initial_setup
    show_completion
}

# Run main function
main "$@"