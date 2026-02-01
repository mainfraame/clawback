"""
Telegram notification system for trading alerts
"""
import logging
import json
import os
from datetime import datetime
import requests

logger = logging.getLogger(__name__)


def get_local_timestamp():
    """Get current timestamp formatted in local timezone"""
    return datetime.now().astimezone().strftime('%Y-%m-%d %H:%M:%S %Z')

class TelegramNotifier:
    """Sends Telegram notifications for trading activities"""
    
    def __init__(self, config):
        self.config = config.get('telegram', {})
        self.enabled = self.config.get('enabled', False)
        self.bot_token = self.config.get('botToken', '')
        self.chat_id = self.config.get('chatId', '')
        
        if self.enabled and (not self.bot_token or not self.chat_id):
            logger.warning("Telegram enabled but token or chat ID missing")
            self.enabled = False
        
        logger.info(f"Telegram notifier initialized: {'ENABLED' if self.enabled else 'DISABLED'}")
    
    def send_message(self, message, parse_mode='Markdown'):
        """Send a message to Telegram"""
        if not self.enabled:
            return False
        
        try:
            url = f"https://api.telegram.org/bot{self.bot_token}/sendMessage"
            payload = {
                "chat_id": self.chat_id,
                "text": message,
                "parse_mode": parse_mode,
                "disable_web_page_preview": True
            }
            
            response = requests.post(url, json=payload, timeout=10)
            
            if response.status_code == 200:
                logger.debug("Telegram message sent successfully")
                return True
            else:
                logger.error(f"Telegram API error: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Error sending Telegram message: {e}")
            return False
    
    def send_trade_alert(self, trade_action, details):
        """Send trade execution alert"""
        if not self.config.get('sendTradeAlerts', True):
            return False
        
        symbol = details.get('symbol', 'Unknown')
        action = trade_action.upper()
        quantity = details.get('quantity', 0)
        price = details.get('price', 0)
        total = details.get('total', 0)
        reason = details.get('reason', '')
        
        message = f"""
🚀 *TRADE EXECUTED* 🚀

*Action:* {action} {symbol}
*Quantity:* {quantity} shares
*Price:* ${price:.2f}
*Total:* ${total:.2f}
*Reason:* {reason}

*Time:* {get_local_timestamp()}
"""
        
        return self.send_message(message.strip())
    
    def send_congressional_alert(self, trade):
        """Send congressional trade alert"""
        politician = trade.get('politician', 'Unknown')
        symbol = trade.get('ticker', 'Unknown')
        action = trade.get('transaction_type', '').upper()
        amount = trade.get('amount', 0)
        date = trade.get('transaction_date', '')
        
        message = f"""
📊 *CONGRESSIONAL TRADE ALERT* 📊

*Politician:* {politician}
*Action:* {action} {symbol}
*Amount:* ${amount:,.2f}
*Date:* {date}

*Time Detected:* {get_local_timestamp()}
"""
        
        return self.send_message(message.strip())
    
    def send_error_alert(self, error_type, error_message, context=""):
        """Send generic error alert"""
        if not self.config.get('sendErrorAlerts', True):
            return False

        message = f"""
⚠️ *SYSTEM ERROR* ⚠️

*Type:* {error_type}
*Error:* {error_message}
*Context:* {context}
*Time:* {get_local_timestamp()}
"""

        return self.send_message(message.strip())

    def send_broker_error(self, operation, error_message, details=None, broker_name=None):
        """Send broker API error alert"""
        if not self.config.get('sendErrorAlerts', True):
            return False

        details_text = ""
        if details:
            if isinstance(details, dict):
                details_text = "\n".join([f"  • {k}: {v}" for k, v in details.items()])
            else:
                details_text = str(details)

        broker_display = broker_name.replace('*', '\\*') if broker_name else "Unknown"

        message = f"""
🚨 *BROKER API ERROR* 🚨

*Operation:* {operation}
*Error:* `{error_message}`
{f"*Details:*{chr(10)}{details_text}" if details_text else ""}
*Broker:* {broker_display}
*Time:* {get_local_timestamp()}

⚡ _Action may be required_ ⚡
"""

        return self.send_message(message.strip())

    def send_disclosure_error(self, source, error_message, details=None):
        """Send disclosure poll error alert"""
        if not self.config.get('sendErrorAlerts', True):
            return False

        source_emoji = "🏛️" if source.lower() == "house" else "🏛️" if source.lower() == "senate" else "📊"

        details_text = ""
        if details:
            if isinstance(details, dict):
                details_text = "\n".join([f"  • {k}: {v}" for k, v in details.items()])
            else:
                details_text = str(details)

        message = f"""
{source_emoji} *DISCLOSURE POLL FAILED* {source_emoji}

*Source:* {source}
*Error:* `{error_message}`
{f"*Details:*{chr(10)}{details_text}" if details_text else ""}
*Time:* {get_local_timestamp()}

📋 _Will retry at next scheduled check_
"""

        return self.send_message(message.strip())

    def send_market_status(self, status, pending_trades=0):
        """Send market status notification"""
        if status == "closed":
            message = f"""
🌙 *MARKET CLOSED*

*Pending Trades:* {pending_trades}
*Next Action:* Execute at market open (9:35 AM ET)
*Time:* {get_local_timestamp()}
"""
        else:
            message = f"""
☀️ *MARKET OPEN*

*Status:* Trading enabled
*Pending Trades:* {pending_trades}
*Time:* {get_local_timestamp()}
"""

        return self.send_message(message.strip())
    
    def send_daily_summary(self, summary_data):
        """Send daily trading summary"""
        if not self.config.get('sendDailySummary', True):
            return False
        
        date = summary_data.get('date', datetime.now().astimezone().strftime('%Y-%m-%d'))
        trades_made = summary_data.get('trades_made', 0)
        total_volume = summary_data.get('total_volume', 0)
        pnl = summary_data.get('pnl', 0)
        account_balance = summary_data.get('account_balance', 0)
        
        pnl_emoji = "📈" if pnl >= 0 else "📉"
        
        message = f"""
📋 *DAILY TRADING SUMMARY* 📋

*Date:* {date}
*Trades Made:* {trades_made}
*Total Volume:* ${total_volume:,.2f}
*Daily P&L:* {pnl_emoji} ${pnl:,.2f}
*Account Balance:* ${account_balance:,.2f}

*Summary Time:* {get_local_timestamp()}
"""
        
        return self.send_message(message.strip())
    
    def send_test_message(self, broker_name=None, account_balance=None, is_authenticated=False):
        """Send test message to verify setup with actual system state"""
        # Format broker display name (escape markdown special chars)
        broker_display = (broker_name or "Not configured").replace('*', '\\*').replace('_', '\\_')

        # Format account balance
        if account_balance is not None:
            balance_display = f"${account_balance:,.2f}"
        else:
            balance_display = "Not available"

        # Format auth status
        auth_status = "Authenticated ✓" if is_authenticated else "Not authenticated"

        message = f"""
✅ *CLAWBACK SYSTEM TEST* ✅

*System:* ClawBack Congressional Trading Bot
*Broker:* {broker_display}
*Auth Status:* {auth_status}
*Account Balance:* {balance_display}
*Time:* {get_local_timestamp()}

{"System ready to trade!" if is_authenticated else "⚠️ Please authenticate before trading."}
"""

        success = self.send_message(message.strip())
        if success:
            logger.info("Telegram test message sent successfully")
        return success