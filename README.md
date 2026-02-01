# ClawBack 🦀

**Mirror congressional stock trades with automated broker execution**

[![ClawHub](https://img.shields.io/badge/ClawHub-clawback-blue)](https://www.clawhub.ai/skills/clawback)
[![Version](https://img.shields.io/badge/version-1.0.4-green)](https://github.com/mainfraame/clawback/releases)
[![Python](https://img.shields.io/badge/python-3.9+-blue)](https://python.org)

ClawBack tracks stock trades disclosed by members of Congress and executes scaled positions in your brokerage account. Built on the premise that congressional leaders consistently outperform the market.

## Installation

### Via ClawHub (Recommended)

```bash
# Install from ClawHub registry
clawhub install clawback

# Run setup wizard
clawback setup
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/mainfraame/clawback.git
cd clawback

# Install
pip install -e .

# Run setup
clawback setup
```

### From Source with Make

```bash
git clone https://github.com/mainfraame/clawback.git
cd clawback

# Create venv and install
make deps

# Activate and setup
source venv/bin/activate
clawback setup
```

## Quick Start

```bash
# Check system status
clawback status

# Run interactive trading mode
clawback run

# Run as background daemon
clawback daemon
```

## Configuration

Configuration is stored in `~/.clawback/config.json`. The setup wizard will guide you through:

1. **Broker Selection** - E*TRADE (currently the only supported broker)
2. **Environment** - Sandbox (testing) or Production (real money)
3. **API Credentials** - From E*TRADE developer portal
4. **Account Selection** - Choose which account to trade
5. **Telegram Notifications** - Optional alerts via Telegram

### Environment Variables

```bash
# E*TRADE API (required)
BROKER_API_KEY=your_consumer_key
BROKER_API_SECRET=your_consumer_secret
BROKER_ACCOUNT_ID=your_account_id

# Telegram (optional)
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id
```

## Features

- **Real-time disclosure tracking** from official House Clerk and Senate eFD sources
- **Automated trade execution** via E*TRADE API
- **Smart position sizing** - scales trades to your account size
- **Risk management** - stop-losses, drawdown limits, position limits
- **Telegram notifications** - alerts for new trades and events
- **OpenClaw integration** - works as an OpenClaw skill

## Architecture

| Component | Description |
|-----------|-------------|
| Congressional Tracker | Fetches trade data from official disclosures |
| Broker Adapter | Handles authentication and trading (E*TRADE) |
| Trade Engine | Executes orders with risk management |
| Telegram Notifier | Sends alerts and notifications |
| Database | SQLite storage for trades and positions |

## Data Sources

- **House Clerk**: https://disclosures-clerk.house.gov (PDF parsing)
- **Senate eFD**: https://efdsearch.senate.gov (web scraping)

## Risk Management

| Control | Default |
|---------|---------|
| Max position size | 5% of portfolio |
| Max positions | 20 |
| Daily loss limit | 3% |
| Portfolio stop-loss | 15% |
| Position stop-loss | 8% |

## Development

```bash
# Show all make commands
make help

# Version management
make bump-patch    # 1.0.4 → 1.0.5
make bump-minor    # 1.0.4 → 1.1.0
make bump-major    # 1.0.4 → 2.0.0

# Release workflow
make release       # commit, tag, push
make publish       # publish to ClawHub

# All-in-one
make ship-patch    # bump + release + publish
```

## Support

- **Issues**: https://github.com/mainfraame/clawback/issues
- **ClawHub**: https://www.clawhub.ai/skills/clawback

## Disclaimer

**Trading involves substantial risk of loss.** This software is for educational purposes only. Past congressional trading performance does not guarantee future results. Always test with sandbox accounts before live trading.

---

**Version**: 1.0.4 | **License**: MIT | **Author**: [mainfraame](https://github.com/mainfraame)
