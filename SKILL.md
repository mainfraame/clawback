---
name: clawback
description: Mirror congressional stock trades with automated broker execution and risk management. Use when you want to track and automatically trade based on congressional disclosures from House Clerk and Senate eFD sources.
version: 1.0.10
author: mainfraame
homepage: https://github.com/mainfraame/clawback
user-invocable: true
metadata: {"openclaw": {"emoji": "🦀", "requires": {"bins": ["python3", "pip"]}, "install": {"pip": "{baseDir}"}, "primaryEnv": "BROKER_API_KEY"}}
---

# ClawBack

**Mirror congressional stock trades with automated broker execution**

ClawBack tracks stock trades disclosed by members of Congress (House and Senate) and executes scaled positions in your E*TRADE brokerage account. Built on the premise that congressional leaders consistently outperform the market due to informational advantages.

## Features

- **Real-time disclosure tracking** from official House Clerk and Senate eFD sources
- **Automated trade execution** via E*TRADE API (only supported broker)
- **Smart position sizing** - scales trades to your account size
- **Trailing stop-losses** - lock in profits, limit losses
- **Risk management** - drawdown limits, consecutive loss protection
- **Telegram notifications** - get alerts for new trades and stop-losses
- **Backtesting engine** - test strategies on historical data

## Performance (Backtest Results)

| Strategy | Win Rate | Return | Sharpe |
|----------|----------|--------|--------|
| 3-day delay, 30-day hold | 42.9% | +6.2% | 0.39 |
| 9-day delay, 90-day hold | 57.1% | +4.7% | 0.22 |

Congressional leaders have outperformed the S&P 500 by 47% annually according to NBER research.

## Installation via ClawHub

```bash
# Install from ClawHub registry
clawhub install clawback

# Or install from local directory
clawhub install ./clawback
```

### Post-Installation Setup

After installation via ClawHub, the `install.sh` script runs automatically:

1. **Python Environment Setup** - Creates virtual environment
2. **Package Installation** - Installs ClawBack via pip
3. **Directory Structure** - Creates logs/, data/, config/ directories
4. **Setup Prompt** - Asks if you want to run the setup wizard

If you skip setup during installation, run it manually:
```bash
cd ~/.openclaw/skills/clawback
./setup.sh          # Interactive setup wizard
# or
clawback setup      # CLI-based setup
```

### Improved Setup Features

- **Better input handling** - Works in both interactive and non-interactive modes
- **Input validation** - Validates E*TRADE API key formats
- **Timeout handling** - Automatically uses defaults if no input
- **Error recovery** - Fallback to manual setup if CLI fails
- **Configuration check** - Detects existing config and offers options

## Interactive Setup Wizard

The setup wizard guides you through configuration:

### Step 1: Environment Selection
- **Sandbox** (recommended for testing): No real trades, uses E*TRADE developer sandbox
- **Production**: Real trading with real money

### Step 2: E*TRADE API Credentials
- **Consumer Key**: From E*TRADE developer portal
- **Consumer Secret**: From E*TRADE developer portal

### Step 3: Authentication
- Automatic OAuth flow with E*TRADE
- Opens browser for authorization
- Returns verification code

### Step 4: Account Selection
- Lists all available E*TRADE accounts
- Choose which account to trade with

### Step 5: Telegram Setup (Optional)
- Configure notifications via Telegram bot
- Uses OpenClaw's built-in Telegram channel if available

## Environment Variables

After setup, credentials are stored in `.env`:

```bash
# E*TRADE API (required)
BROKER_API_KEY=your_consumer_key_here
BROKER_API_SECRET=your_consumer_secret_here
BROKER_ACCOUNT_ID=your_account_id_here

# Telegram (optional)
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here

# FMP API (optional)
FMP_API_KEY=your_fmp_api_key_here
```

## Usage

```bash
# Use the installed CLI command
clawback run      # Start interactive trading mode
clawback daemon   # Run as background service
clawback status   # Check system status
clawback setup    # Re-run setup wizard
clawback test     # Test Telegram notifications
```

## Automated Trading

The `clawback daemon` command runs continuously with:
- **Disclosure checks** at 10:00, 14:00, 18:00 ET (when filings are typically released)
- **Trade execution** at 9:35 AM ET (5 min after market open)
- **Token refresh** every 90 minutes (keeps E*TRADE session alive)
- **Market hours enforcement** (9:30 AM - 4:00 PM ET)

## Data Sources

- **House Clerk**: https://disclosures-clerk.house.gov (PDF parsing)
- **Senate eFD**: https://efdsearch.senate.gov (web scraping)
- **Financial Modeling Prep**: Enhanced financial data (optional)

## Supported Brokers

ClawBack currently only supports E*TRADE. The adapter pattern allows for future broker support, but only E*TRADE is implemented and tested.

| Broker | Adapter | Status |
|--------|---------|--------|
| E*TRADE | `etrade_adapter.py` | Supported |

## Risk Management

- **Position limits**: 5% max per symbol, 20 positions max
- **Stop-losses**: 8% per position, 15% portfolio drawdown
- **Daily limits**: 3% max daily loss
- **PDT compliance**: Conservative 2 trades/day limit

## Security

- No hardcoded credentials in source code
- Environment variable based configuration
- Encrypted token storage for E*TRADE
- Git-ignored `.env` file
- Optional production encryption

## Support

- **Documentation**: See README.md for detailed setup
- **Issues**: https://github.com/mainfraame/clawback/issues
- **Community**: https://discord.com/invite/clawd

## Disclaimer

**Trading involves substantial risk of loss.** This software is for educational purposes only. Past congressional trading performance does not guarantee future results. Always test with E*TRADE sandbox accounts before live trading.