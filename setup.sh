#!/bin/bash

# ClawBack Congressional Trading System - Interactive Setup
# Complete installation with interactive configuration wizard

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

# Check if we're in the right directory
if [ ! -f "requirements.txt" ]; then
    print_error "Must run from ClawBack project directory"
    echo "Expected: requirements.txt"
    echo "Current: $(pwd)"
    exit 1
fi

print_header "ClawBack Congressional Trading System"
echo "Mirror congressional stock trades with automated execution"
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

# Step 3: Install dependencies
print_step "3. Installing Python dependencies..."
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt > /dev/null 2>&1

# Install additional dependencies
print_info "Installing additional packages..."
pip install pdfplumber selenium yfinance schedule python-dotenv requests-oauthlib > /dev/null 2>&1
print_success "Dependencies installed"

# Step 4: Create directories
print_step "4. Creating directory structure..."
mkdir -p logs data config scripts
print_success "Directories created"

# Step 5: Interactive Configuration
print_header "Configuration Wizard"

# Check if config already exists
if [ -f "config/config.json" ] && [ -f ".env" ]; then
    print_info "Configuration already exists"
    read -p "Do you want to reconfigure? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_success "Setup complete! Using existing configuration."
        echo ""
        echo "To start trading:"
        echo "  python3 src/main.py interactive"
        echo ""
        echo "To set up automation:"
        echo "  ./scripts/setup_cron.sh"
        exit 0
    fi
fi

# Step 6: Broker Selection
print_step "5. Broker Configuration"
echo "Currently supported brokers:"
echo "  [1] E*TRADE (sandbox - recommended for testing)"
echo "  [2] E*TRADE (production - real trading)"
echo ""

while true; do
    read -p "Select broker (1/2): " BROKER_CHOICE
    case $BROKER_CHOICE in
        1)
            BROKER="etrade"
            ENVIRONMENT="sandbox"
            print_info "Selected: E*TRADE Sandbox"
            echo "Get API keys from: https://developer.etrade.com"
            break
            ;;
        2)
            BROKER="etrade"
            ENVIRONMENT="production"
            print_info "Selected: E*TRADE Production"
            echo "Get API keys from: https://us.etrade.com/etx/ris/apikey"
            break
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 2."
            ;;
    esac
done

echo ""

# Step 7: API Credentials
print_step "6. API Credentials"
read -p "Enter E*TRADE API Key (Consumer Key): " API_KEY
read -p "Enter E*TRADE API Secret (Consumer Secret): " API_SECRET

if [ -z "$API_KEY" ] || [ -z "$API_SECRET" ]; then
    print_warning "API credentials not provided. You can add them later in .env file."
    API_KEY=""
    API_SECRET=""
else
    print_success "API credentials saved"
fi

# Step 8: Telegram Configuration
print_step "7. Telegram Notifications (Optional)"
read -p "Enable Telegram notifications? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Create a bot with @BotFather and get your chat ID from @userinfobot"
    read -p "Telegram Bot Token: " TELEGRAM_TOKEN
    read -p "Telegram Chat ID: " TELEGRAM_CHAT_ID
    
    if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        print_warning "Telegram credentials incomplete. You can add them later."
        TELEGRAM_TOKEN=""
        TELEGRAM_CHAT_ID=""
    else
        print_success "Telegram configured"
    fi
else
    TELEGRAM_TOKEN=""
    TELEGRAM_CHAT_ID=""
    print_info "Telegram notifications disabled"
fi

# Step 9: FMP API (Optional)
print_step "8. Financial Modeling Prep API (Optional)"
read -p "Enable FMP API for enhanced data? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Get API key from: https://financialmodelingprep.com/developer"
    read -p "FMP API Key: " FMP_API_KEY
    
    if [ -z "$FMP_API_KEY" ]; then
        print_warning "FMP API key not provided. You can add it later."
        FMP_API_KEY=""
    else
        print_success "FMP API configured"
    fi
else
    FMP_API_KEY=""
    print_info "FMP API disabled"
fi

# Step 10: Create .env file
print_step "9. Creating configuration files..."

# Create .env file
cat > .env << EOF
# ClawBack Configuration
# Generated on $(date)
# NEVER commit this file to version control

# E*TRADE API Credentials
BROKER_API_KEY=$API_KEY
BROKER_API_SECRET=$API_SECRET
BROKER_ACCOUNT_ID=

# Telegram Notifications
TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID

# Financial Modeling Prep API
FMP_API_KEY=$FMP_API_KEY
EOF

print_success ".env file created"

# Create config template if it doesn't exist
if [ ! -f "config/config.template.json" ]; then
    cat > config/config.template.json << 'EOF'
{
  "broker": {
    "adapter": "etrade",
    "environment": "sandbox",
    "credentials": {
      "apiKey": "${BROKER_API_KEY}",
      "apiSecret": "${BROKER_API_SECRET}"
    }
  },
  "trading": {
    "accountId": "${BROKER_ACCOUNT_ID}",
    "initialCapital": 50000,
    "tradeScalePercentage": 0.02,
    "maxPositionPercentage": 0.10,
    "maxPositions": 10,
    "dailyLossLimit": 0.01,
    "portfolioStopLoss": 0.15,
    "positionStopLoss": 0.08,
    "tradeDelayDays": 3,
    "holdingPeriodDays": 30,
    "marketHoursOnly": true,
    "marketOpen": "09:30",
    "marketClose": "16:00"
  },
  "schedule": {
    "disclosureCheckTimes": ["10:00", "14:00", "18:00"],
    "timezone": "America/New_York"
  },
  "strategy": {
    "entryDelayDays": 3,
    "holdingPeriodDays": 30,
    "purchasesOnly": true,
    "minimumTradeSize": 50000,
    "maxSectorExposure": 0.25,
    "prioritizeLeadership": true,
    "multiMemberBonus": true
  },
  "congress": {
    "dataSource": "official",
    "pollIntervalHours": 24,
    "minimumTradeSize": 50000,
    "tradeTypes": ["purchase"],
    "includeSenate": true,
    "targetPoliticians": [
      {"name": "Nancy Pelosi", "chamber": "house", "priority": 1},
      {"name": "Dan Crenshaw", "chamber": "house", "priority": 2},
      {"name": "Tommy Tuberville", "chamber": "senate", "priority": 2},
      {"name": "Marjorie Taylor Greene", "chamber": "house", "priority": 3}
    ]
  },
  "riskManagement": {
    "maxDrawdown": 0.15,
    "dailyLossLimit": 0.01,
    "positionStopLoss": 0.08,
    "trailingStopActivation": 0.10,
    "trailingStopPercent": 0.05,
    "consecutiveLossLimit": 3
  },
  "logging": {
    "level": "info",
    "file": "logs/trading.log",
    "maxSize": "10MB",
    "maxFiles": 10
  },
  "database": {
    "path": "data/trading.db"
  },
  "notifications": {
    "telegram": {
      "enabled": true,
      "useOpenClaw": true,
      "chatId": "${TELEGRAM_CHAT_ID}",
      "botToken": "${TELEGRAM_BOT_TOKEN}"
    }
  }
}
EOF
    print_success "Config template created"
fi

# Copy template to config if it doesn't exist
if [ ! -f "config/config.json" ]; then
    cp config/config.template.json config/config.json
    
    # Update environment in config
    python3 -c "
import json
with open('config/config.json', 'r') as f:
    config = json.load(f)
config['broker']['environment'] = '$ENVIRONMENT'
with open('config/config.json', 'w') as f:
    json.dump(config, f, indent=2)
"
    print_success "Config file created with $ENVIRONMENT environment"
fi

# Step 11: Test configuration
print_step "10. Testing configuration..."
if python3 -c "
import sys
sys.path.append('src')
try:
    from clawback.config_loader import load_config
    config = load_config('config/config.json')
    print('Configuration loaded successfully')
    print(f'  Broker: {config[\"broker\"].get(\"adapter\", \"not set\")}')
    print(f'  Environment: {config[\"broker\"].get(\"environment\", \"not set\")}')
except Exception as e:
    print(f'Error loading config: {e}')
    sys.exit(1)
"; then
    print_success "Configuration test passed"
else
    print_warning "Configuration test had issues (expected if credentials not set)"
fi

# Step 12: Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environment
venv/
env/
ENV/

# Environment variables
.env
.secrets.json
*.env

# Secrets and credentials
config/secrets.json
*.pem
*.key
*.crt

# Logs
logs/
*.log

# Data files
data/
*.db
*.sqlite
*.sqlite3

# E*TRADE tokens
.access_tokens.json
.auth_state.json

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF
    print_success ".gitignore created"
fi

# Step 13: Final instructions
print_header "Setup Complete! 🎉"

echo -e "${GREEN}✅ ClawBack is ready to use!${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. ${CYAN}Authenticate with E*TRADE:${NC}"
echo "   python3 src/main.py interactive"
echo "   Select option 1 to authenticate"
echo ""
echo "2. ${CYAN}Test the system:${NC}"
echo "   python3 src/main.py interactive"
echo "   Select option 2 to check congressional data"
echo "   Select option 3 to test trading"
echo ""
echo "3. ${CYAN}Set up automation (optional):${NC}"
echo "   ./scripts/setup_cron.sh"
echo ""
echo "4. ${CYAN}Run backtest to validate strategy:${NC}"
echo "   python3 src/backtester.py"
echo ""
echo "Important files created:"
echo "  • ${YELLOW}.env${NC} - Your credentials (DO NOT COMMIT)"
echo "  • ${YELLOW}config/config.json${NC} - Main configuration"
echo "  • ${YELLOW}.gitignore${NC} - Git ignore rules"
echo ""
echo "${YELLOW}⚠️  WARNING: Trading involves risk. Always test with sandbox first!${NC}"
echo ""
echo "For help:"
echo "  • Read README.md for detailed instructions"
echo "  • Check logs/trading.log for debugging"
echo "  • Run 'python3 src/main.py --help' for command options"