#!/bin/bash

# ClawBack Installation Script for ClawHub
# This script runs after the skill is installed via ClawHub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

print_step() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Function to check if running in interactive terminal
is_interactive() {
    [[ -t 0 ]] && [[ -t 1 ]]
}

# Function to read input with fallback for non-interactive mode
safe_read() {
    local prompt="$1"
    local variable="$2"
    local default="$3"
    
    if is_interactive; then
        read -p "$prompt" response
        eval "$variable=\"\${response:-$default}\""
    else
        # Non-interactive mode, use default
        eval "$variable=\"$default\""
        echo "$prompt [using default: $default]"
    fi
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

print_header "ClawBack Congressional Trading System"
echo "Seamless installation via ClawHub"
echo ""

# Step 1: Check Python
print_step "1. Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is required but not installed"
    echo "Install with: brew install python3 (macOS) or apt install python3 (Linux)"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
print_success "Python $PYTHON_VERSION detected"

# Step 2: Create virtual environment
print_step "2. Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_success "Virtual environment already exists"
fi

# Activate virtual environment
source venv/bin/activate

# Step 3: Install Python package
print_step "3. Installing ClawBack Python package..."
if [ -f "pyproject.toml" ]; then
    pip install --upgrade pip > /dev/null 2>&1
    pip install -e . > /dev/null 2>&1
    print_success "ClawBack package installed"
    
    # Verify installation
    if command -v clawback &> /dev/null; then
        print_success "CLI command 'clawback' is available"
    else
        print_warning "CLI command not in PATH. Try: source venv/bin/activate"
    fi
else
    print_error "pyproject.toml not found - cannot install Python package"
    exit 1
fi

# Step 4: Create necessary directories
print_step "4. Creating directory structure..."
mkdir -p logs data config scripts
print_success "Directories created"

# Create installation log
echo "$(date): ClawBack installed via ClawHub" > logs/installation.log

# Step 5: Check if setup already completed
print_step "5. Checking for existing configuration..."
CONFIG_EXISTS=false
if [ -f "config/config.json" ] && [ -f ".env" ]; then
    CONFIG_EXISTS=true
fi

if [ "$CONFIG_EXISTS" = true ]; then
    print_info "Configuration already exists"
    echo ""
    echo "To reconfigure, run:"
    echo "  ./setup.sh"
    echo ""
    echo "To start using ClawBack:"
    echo "  clawback run      # Interactive mode"
    echo "  clawback status   # Check system status"
    echo ""
    exit 0
fi

# Step 6: Prompt for setup (only if interactive)
if is_interactive; then
    print_header "Setup Required"
    echo ""
    echo "ClawBack needs to be configured before first use."
    echo ""
    echo "The setup wizard will guide you through:"
    echo "  1. E*TRADE environment selection (sandbox/production)"
    echo "  2. API credential entry"
    echo "  3. Account authentication"
    echo "  4. Optional Telegram setup"
    echo ""
    
    safe_read "Run setup wizard now? (y/n): " RUN_SETUP "n"
    
    if [[ "$RUN_SETUP" =~ ^[Yy]$ ]]; then
        print_step "Starting setup wizard..."
        # Use the simple setup script that works with CLI
        if [ -f "setup_simple.sh" ]; then
            ./setup_simple.sh
        elif [ -f "setup.sh" ]; then
            ./setup.sh
        else
            print_error "Setup script not found"
            echo "Run manual setup: clawback setup"
        fi
    else
        print_info "Setup deferred. You can run it later with:"
        echo "  ./setup.sh"
        echo "  or"
        echo "  clawback setup"
        echo ""
        print_warning "ClawBack will not function until setup is complete."
    fi
else
    # Non-interactive mode
    print_info "Non-interactive mode detected."
    echo ""
    echo "To complete setup, run:"
    echo "  ./setup.sh"
    echo "  or"
    echo "  clawback setup"
fi

print_header "Installation Complete"
echo ""
echo "ClawBack has been installed successfully!"
echo ""

if [ "$CONFIG_EXISTS" = true ]; then
    echo "  ${GREEN}✓ Configuration complete${NC}"
    echo ""
    echo "To use ClawBack:"
    echo "  clawback status   # Check system status"
    echo "  clawback run      # Start interactive trading"
    echo "  clawback test     # Run tests"
else
    echo "  ${YELLOW}⚠ Configuration pending${NC}"
    echo ""
    echo "To complete setup:"
    echo "  ./setup.sh        # Run setup wizard"
    echo "  or"
    echo "  clawback setup    # Use CLI setup"
fi

echo ""
echo "Documentation:"
echo "  • Read SKILL.md for detailed instructions"
echo "  • Run 'clawback --help' for command reference"
echo "  • Check logs/installation.log for details"
echo ""
echo "${YELLOW}⚠️  WARNING: Trading involves risk. Always test with sandbox first!${NC}"
echo ""