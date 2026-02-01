---
name: clawback
description: Mirror congressional stock trades with automated broker execution. Use /clawback setup to configure, or /clawback status to check.
version: 1.1.0
author: mainfraame
homepage: https://github.com/mainfraame/clawback
user-invocable: true
metadata:
  openclaw:
    emoji: "🦀"
    requires:
      bins:
        - python3
        - pip
    install:
      pip: "{baseDir}"
---

# ClawBack - Congressional Trade Mirror

Track and mirror stock trades disclosed by members of Congress.

## First-Time Setup

When user says `/clawback setup` or asks to set up ClawBack:

1. **Install the CLI** (if not already installed):
   ```bash
   pip install ~/.openclaw/workspace/skills/clawback
   ```

2. **Run the setup wizard**:
   ```bash
   clawback setup
   ```
   This prompts for:
   - E*TRADE API credentials (sandbox or production)
   - OAuth authentication (opens browser)
   - Account selection
   - Telegram notification preferences

3. **Add cron jobs for autonomous monitoring**:
   ```bash
   openclaw cron add --name "ClawBack Morning" --cron "0 10 * * 1-5" --tz "America/New_York" --session isolated --message "Run clawback status and report any new congressional disclosures"
   openclaw cron add --name "ClawBack Afternoon" --cron "0 14 * * 1-5" --tz "America/New_York" --session isolated --message "Run clawback status and report any new congressional disclosures"
   openclaw cron add --name "ClawBack Evening" --cron "0 18 * * 1-5" --tz "America/New_York" --session isolated --message "Run clawback status and summarize today's congressional trades"
   ```

4. **Confirm setup** by running:
   ```bash
   clawback status
   ```

## Commands

| Command | Description |
|---------|-------------|
| `clawback setup` | Interactive setup wizard |
| `clawback status` | Check system status and broker connection |
| `clawback run` | Start interactive trading mode |
| `clawback test` | Test Telegram notifications |

## Checking for Disclosures

When asked to check congressional trades or during scheduled cron runs:

```bash
clawback status
```

This shows:
- Broker connection status
- Recent congressional disclosures
- Pending trades
- Account balance

## Executing Trades

ClawBack only executes during market hours (9:30 AM - 4:00 PM ET). When trades are pending:

```bash
clawback run
```

Then select "Execute Pending Trades" from the menu.

## Notifications

ClawBack sends Telegram alerts for:
- New congressional disclosures
- Trade executions
- Broker errors
- Token refresh failures

Notifications use OpenClaw's Telegram channel when available.

## Data Sources

- **House Clerk**: disclosures-clerk.house.gov (PDF parsing)
- **Senate eFD**: efdsearch.senate.gov (web scraping)

Checks run at 10 AM, 2 PM, and 6 PM ET on weekdays.

## Risk Disclaimer

Trading involves substantial risk. This is for educational purposes only. Past congressional trading performance doesn't guarantee future results.
