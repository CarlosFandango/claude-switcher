#!/bin/bash

# Claude Switch - Installation Script
# Automates the complete setup process for the modular version

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/bin"
LIB_INSTALL_DIR="/usr/local/lib/claude-switch"
COMMANDS_DIR="$HOME/.claude/commands"
SCRIPT_NAME="claude-switch"

echo -e "${BLUE}=== Claude Switch Installation ===${NC}"
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
    echo -e "${YELLOW}Checking for Claude Code CLI...${NC}"

    # Check for claude command
    if command_exists claude; then
        echo -e "${GREEN}✓ Claude Code CLI found${NC}"
        return 0
    fi

    # Check for claude-code command
    if command_exists claude-code; then
        echo -e "${GREEN}✓ Claude Code CLI found (claude-code)${NC}"
        return 0
    fi

    # Check if ~/.claude directory exists (indicates previous installation)
    if [ -d "$HOME/.claude" ]; then
        echo -e "${YELLOW}Claude Code configuration directory found, but command not in PATH${NC}"
        echo -e "${YELLOW}You may need to restart your terminal or check your PATH${NC}"
        return 0
    fi

    # Claude Code CLI not found
    echo -e "${RED}✗ Claude Code CLI not found${NC}"
    echo ""
    echo -e "${YELLOW}This tool requires Claude Code CLI to be installed first.${NC}"
    echo ""
    echo -e "${BLUE}To install Claude Code CLI:${NC}"
    echo "1. Visit: https://docs.anthropic.com/en/docs/claude-code/quickstart"
    echo "2. Follow the installation instructions for your platform"
    echo "3. Run Claude Code at least once to create initial configuration"
    echo "4. Then re-run this installation script"
    echo ""
    echo -e "${YELLOW}Quick install option:${NC}"
    echo "  macOS: curl -fsSL https://claude.ai/install.sh | sh"
    echo ""

    read -p "Would you like to continue anyway? (y/N): " continue_anyway
    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        echo "Installation cancelled. Please install Claude Code CLI first."
        exit 1
    fi

    echo -e "${YELLOW}Continuing without Claude Code CLI verification...${NC}"
    # Create claude directory structure manually
    mkdir -p "$COMMANDS_DIR"
}

# Function to check macOS
check_macos() {
    echo -e "${YELLOW}Checking operating system...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${GREEN}✓ Running on macOS${NC}"

        # Check for security command (keychain access)
        if ! command_exists security; then
            echo -e "${RED}✗ macOS security command not found${NC}"
            echo "This is unusual for macOS. Keychain integration may not work."
            exit 1
        fi

        return 0
    else
        echo -e "${RED}✗ This version requires macOS${NC}"
        echo "Keychain integration is currently macOS-only."
        echo ""
        echo "For Linux support, you would need to implement Secret Service integration."
        exit 1
    fi
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

# Function to install library modules
install_lib_modules() {
    echo -e "${YELLOW}Installing library modules...${NC}"

    if [ ! -d "lib" ]; then
        echo -e "${RED}Error: lib directory not found in current directory${NC}"
        echo "Please run this script from the claude-switch repository root"
        exit 1
    fi

    # Create lib installation directory
    echo "Installing libraries to $LIB_INSTALL_DIR (requires sudo)..."
    sudo mkdir -p "$LIB_INSTALL_DIR"

    # Copy all lib files
    sudo cp -r lib/* "$LIB_INSTALL_DIR/"

    # Set permissions
    sudo chmod -R 755 "$LIB_INSTALL_DIR"

    echo -e "${GREEN}✓ Library modules installed${NC}"
}

# Function to install main script
install_main_script() {
    echo -e "${YELLOW}Installing main script...${NC}"

    if [ ! -f "$SCRIPT_NAME" ]; then
        echo -e "${RED}Error: $SCRIPT_NAME not found in current directory${NC}"
        echo "Please run this script from the directory containing $SCRIPT_NAME"
        exit 1
    fi

    # Create a wrapper script that knows where to find libs
    local wrapper_script="/tmp/${SCRIPT_NAME}-wrapper"

    cat > "$wrapper_script" << 'EOF'
#!/bin/bash

# Claude Switch Wrapper - Points to installed library modules

# Get the directory where the script is located
SCRIPT_DIR="/usr/local/lib/claude-switch"
LIB_DIR="$SCRIPT_DIR"

# Source all library modules
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/validation.sh"
source "$LIB_DIR/api.sh"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/wizard.sh"

# Version
VERSION="2.0.0"

# Initialize configuration directories
init_config_dirs

EOF

    # Append the main script logic (skip the shebang and initial sourcing)
    tail -n +18 "$SCRIPT_NAME" >> "$wrapper_script"

    # Make executable
    chmod +x "$wrapper_script"

    # Copy to system path
    echo "Installing to $INSTALL_DIR (requires sudo)..."
    sudo cp "$wrapper_script" "$INSTALL_DIR/$SCRIPT_NAME"

    # Clean up temp file
    rm "$wrapper_script"

    # Verify installation
    if command_exists "$SCRIPT_NAME"; then
        echo -e "${GREEN}✓ Main script installed successfully${NC}"
    else
        echo -e "${RED}✗ Installation failed - script not found in PATH${NC}"
        exit 1
    fi
}

# Function to install Claude Code CLI integration
install_claude_integration() {
    echo -e "${YELLOW}Installing Claude Code CLI integration...${NC}"

    if [ ! -f "litellm.md" ]; then
        echo -e "${YELLOW}Warning: litellm.md not found, skipping Claude Code CLI integration${NC}"
        return 0
    fi

    # Create commands directory if it doesn't exist
    mkdir -p "$COMMANDS_DIR"

    # Copy slash command
    cp "litellm.md" "$COMMANDS_DIR/"

    echo -e "${GREEN}✓ Claude Code CLI integration installed${NC}"
    echo -e "  Slash command available: ${BLUE}/litellm${NC}"
}

# Function to run initial setup
run_initial_setup() {
    echo -e "${YELLOW}Testing installation...${NC}"

    # Test basic functionality
    if ! "$SCRIPT_NAME" version >/dev/null 2>&1; then
        echo -e "${RED}✗ Installation test failed${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Installation test passed${NC}"

    # Prompt for configuration setup
    echo ""
    echo -e "${BLUE}Initial Configuration${NC}"
    echo "Would you like to run the setup wizard now? (Y/n)"
    read -r run_setup

    if [[ ! $run_setup =~ ^[Nn]$ ]]; then
        echo ""
        "$SCRIPT_NAME" setup
    else
        echo -e "${YELLOW}You can run the setup wizard later using:${NC}"
        echo "  $SCRIPT_NAME setup"
    fi
}

# Function to show completion message
show_completion() {
    echo ""
    echo -e "${GREEN}=== Installation Complete! ===${NC}"
    echo ""
    echo -e "${BLUE}Quick Start:${NC}"
    echo "  $SCRIPT_NAME setup          # Run interactive setup wizard"
    echo "  $SCRIPT_NAME help           # Show all commands"
    echo "  $SCRIPT_NAME status         # Check current configuration"
    echo "  $SCRIPT_NAME list           # List all profiles"
    echo "  $SCRIPT_NAME model list     # List available models"
    echo ""
    echo -e "${BLUE}Profile Management:${NC}"
    echo "  $SCRIPT_NAME create         # Create a new profile"
    echo "  $SCRIPT_NAME switch <name>  # Switch to a profile"
    echo "  $SCRIPT_NAME delete <name>  # Delete a profile"
    echo ""
    echo -e "${BLUE}Claude Code CLI Integration:${NC}"
    echo "  /litellm                    # Access from Claude Code CLI"
    echo ""
    echo -e "${YELLOW}For detailed documentation, see README.md${NC}"
}

# Main installation flow
main() {
    # Check for macOS
    check_macos

    # Check for Claude Code CLI
    check_claude_cli

    # Check if already installed
    if command_exists "$SCRIPT_NAME"; then
        echo -e "${YELLOW}Claude Switch appears to already be installed.${NC}"
        echo "Would you like to reinstall/update? (y/N)"
        read -r reinstall
        if [[ ! $reinstall =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi

    install_dependencies
    install_lib_modules
    install_main_script
    install_claude_integration
    run_initial_setup
    show_completion
}

# Run main function
main "$@"
