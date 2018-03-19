import json
import math
import time
import sys
import requests
import urllib
import ctypes
import os
from win32 import win32gui
from pynput import keyboard


from binance.websockets import BinanceSocketManager
from binance.client import Client
from twisted.internet import reactor
from colorama import init, Fore, Back, Style

# parse parameters sent from ahk gui

order_type = sys.argv[1]
order_symbol = sys.argv[2]
order_amount = float(sys.argv[3])
order_start_price = float(sys.argv[4])
order_stop_price = float(sys.argv[5])
order_trail_percentage = float(sys.argv[6])
order_ratio = float(sys.argv[7])
order_confirmations = int(sys.argv[8])
order_mode = sys.argv[9]
api_key = sys.argv[10]
api_secret = sys.argv[11]
telegram_api = sys.argv[12]
telegram_id = sys.argv[13]

if (api_key == "empty"):
	api_key = ""
if (api_secret == "empty"):
	api_secret = ""

# Fee percentages, adjust here if they are different

fee_bnb = 0.1
fee_other = 0.2

# Telegram API connection

URL = "https://api.telegram.org/bot{}/".format(telegram_api)

def get_url(url):
    response = requests.get(url)
    content = response.content.decode("utf8")
    return content

def send_message(text):
    url = URL + "sendMessage?text={}&chat_id={}".format(text, telegram_id)
    get_url(url)


class currency_container:
	def __init__(self, currencyArray):
		self.symbol = currencyArray['s']
		self.ask_price = float(currencyArray['a'])
		self.bid_price = float(currencyArray['b'])		


def enter_position():
	
	# Get free balance, if not sufficient for fee and fees are not paid in BNB it will need to be substracted from buy qty 
	# to avoid insufficient balance errors on position exit

	symbol_short = order_symbol[:-3]
	balance = client.get_asset_balance(asset=symbol_short)
	balance_free = float(balance.get("free"))

	order = client.create_order(
		 	symbol= order_symbol,
		 	side=Client.SIDE_BUY,
		 	type=Client.ORDER_TYPE_MARKET,
		 	quantity=(order_amount),
			newOrderRespType=Client.ORDER_RESP_TYPE_FULL)
	
	# Get weighted average of buy fills

	fills = order["fills"]
	fill_price_list = []
	fill_qty_list = []
	fill_commission = 0.0

	for fill in fills:
		fill_price = float(fill.get("price"))
		fill_price_list.append(fill_price)
		fill_qty = float(fill.get("qty"))
		fill_qty_list.append(fill_qty)
		commission_asset = fill.get("commissionAsset")
		if commission_asset != "BNB":
			fill_commission += float(fill.get("commission"))
			

	buy_avg_price = sum(x * y for x, y in zip(fill_price_list, fill_qty_list)) / sum(fill_qty_list)
	buy_qty = sum(fill_qty_list)
	
	# If needed substract fees from buy qty

	if commission_asset != "BNB":
		if balance_free < fill_commission:
			buy_qty = buy_qty - fill_commission	

	return buy_avg_price,buy_qty,commission_asset


def exit_position():
	global buy_qty

	# Truncate partial fill to allowed precision set by Binance for this symbol, this may create dust but is not caused by this script

	buy_qty = math.floor(buy_qty * 10 ** qty_precision) / 10 ** qty_precision
	
	order = client.create_order(
	 	symbol= order_symbol,
	 	side=Client.SIDE_SELL,
	 	type=Client.ORDER_TYPE_MARKET,
	 	quantity=(buy_qty),
		newOrderRespType=Client.ORDER_RESP_TYPE_FULL)

	# Get weighted average of sell fills
		
	fills = order["fills"]
	fill_price_list = []
	fill_qty_list = []

	for fill in fills:
		fill_price = float(fill.get("price"))
		fill_price_list.append(fill_price)
		fill_qty = float(fill.get("qty"))
		fill_qty_list.append(fill_qty)
					
	sell_avg_price = sum(x * y for x, y in zip(fill_price_list, fill_qty_list)) / sum(fill_qty_list)
	
	return sell_avg_price
	
	
def get_symbol_info(): # Get Binance price and qty minimum values for symbol
	info = client.get_symbol_info(order_symbol)
			
	filters = info["filters"]
	price_filter = filters[0]
	symbol_ticksize = price_filter.get("tickSize")
	price_filter = filters[1]
	symbol_minqty = price_filter.get("minQty")

	price_precision = symbol_ticksize.find('1') -1
	qty_precision = symbol_minqty.find('1') -1
	if qty_precision == -1:
		qty_precision = 0

	return (price_precision,qty_precision)

		
def process_message_trailing_stop(msg): # Websockets listener and processing for trailing stop type
	global highest_price
	global confirmation
	global price_diff_int_max
	global effective_trail_percentage	
	
	for currency in msg:
		x = currency_container(currency)
		if(x.symbol == order_symbol): 

			# Set highest price to current price if it exceeds previous highest price
			
			current_price = x.bid_price
			if current_price > highest_price:
				highest_price = current_price

			# Calculate current price difference percentage compared to highest price

			price_diff = ((current_price - highest_price) / highest_price) * 100
			price_diff = round(price_diff, 2)
			price_diff = price_diff + 0.0 # eliminates - sign for 0.00 rounded value

			# Calculate percentage total profit/loss

			price_diff_total = ((current_price - buy_avg_price) / buy_avg_price) * 100
			price_diff_total = round(price_diff_total, 2)
			price_diff_total = price_diff_total + 0.0 # eliminates - sign for 0.00 rounded value

			# Substract fee percentage (buy and sell) from total profit/loss percentage, if mode is 'Reset' only count selling fee

			if commission_asset == "BNB":
				if order_mode == "Reset":
					price_diff_total -= (fee_bnb / 2)
				else:
					price_diff_total -= fee_bnb
			else:
				if order_mode == "Reset":
					price_diff_total -= (fee_other / 2)
				else:
					price_diff_total -= fee_other

			# Effective trail percentage calculation based on ratio

			if price_diff_total > 0:
				price_diff_int = int(price_diff_total)
				if price_diff_int > price_diff_int_max:
					effective_trail_percentage = effective_trail_percentage + order_ratio
					price_diff_int_max = price_diff_int
				

			# Convert floats to strings to be used in console output and format to Binance price precision for the symbol
			
			current_price_str = '[c] ' + '{0:.{precision}f}'.format(current_price, precision=price_precision)
			highest_price_str = '[h] ' + '{0:.{precision}f}'.format(highest_price, precision=price_precision)
			price_diff_str = '[ctp] ' +  '{0:.{precision}f}'.format(price_diff, precision='2')
			price_diff_total_str = '[p/l] ' +  '{0:.{precision}f}'.format(price_diff_total, precision='2')
			effective_trail_percentage_str = '[etp] ' +  '{0:.{precision}f}'.format(effective_trail_percentage, precision='1')

			# Add whitespace to non negative percentages to preserve consistent console output spacing

			if price_diff_total >= 0:
				price_diff_total_str = '[p/l]  ' +  '{0:.{precision}f}'.format(price_diff_total, precision='2')			
			
			if price_diff == 0:
				price_diff_str = '[ctp]  ' +  '{0:.{precision}f}'.format(price_diff, precision='2')


			if effective_trail_percentage + price_diff < 0: # If trailing stop condition is met

				# If amount of confirmations set is not reached print to console in yellow
				
				print(Fore.YELLOW, end=" ")
				print (x.symbol, current_price_str,highest_price_str,effective_trail_percentage_str,price_diff_str,price_diff_total_str, sep = ' || ', end="\r", flush=True)				

				confirmation += 1

				# If amount of confirmations set is reached print to console in red close websocket and initiate position exit

				if confirmation == order_confirmations:
					print(Fore.RED, end=" ")
					print (x.symbol, current_price_str,highest_price_str,effective_trail_percentage_str,price_diff_str,price_diff_total_str, sep = ' || ', end="\r", flush=True)	
					print("\n")				
					bm.close()

					# In test mode set the 'sell' price to ask price at the moment stop was triggered, in Real or Reset mode initiate market sell order

					if order_mode == "Test":
						sell_avg_price = current_price
						sell_avg_price_str = '{0:.{precision}f}'.format(sell_avg_price, precision=price_precision)
					else:
						try:
							sell_avg_price = exit_position()
						except:
							message = " Sell order for " + str(order_amount) + " " + order_symbol + " failed!\n Check your balances and sell manually if needed"
							print(Fore.RED)
							print(message)
							if len(telegram_api) > 0:
								try:							
									send_message (message)
								except:
									pass
							bm.close()
							break

						sell_avg_price_str = '{0:.{precision}f}'.format(sell_avg_price, precision=price_precision)

						# Recalculate total profit/loss based on the actual weighted average sell price, if mode is 'Reset' only count selling fee

						price_diff_total = ((sell_avg_price - buy_avg_price) / buy_avg_price) * 100
						price_diff_total = round(price_diff_total, 2)

						if commission_asset == "BNB":
							if order_mode == "Reset":
								price_diff_total -= (fee_bnb / 2)
							else:
								price_diff_total -= fee_bnb
						else:
							if order_mode == "Reset":
								price_diff_total -= (fee_other / 2)
							else:
								price_diff_total -= fee_other


					# Remove [p/l] suffix from total profit/loss percentage string
					
					price_diff_total_str = '{0:.{precision}f}'.format(price_diff_total, precision='2')

					message = " Trailing stop for " + order_symbol + " triggered, entered at: " + buy_avg_price_str + " sold at: " + sell_avg_price_str + "\n" + " Profit/Loss(incl. fees): " + price_diff_total_str + " %"
					print(Fore.CYAN)
					print(message)

					# Send Telegram message if API key is set

					if len(telegram_api) > 0:
						try:
							send_message (message)
						except:
							pass

			else: # If trailing stop condition is not met write to console in green and reset stop confirmation count
				print(Fore.GREEN, end=" ")								
				print (x.symbol, current_price_str,highest_price_str,effective_trail_percentage_str,price_diff_str,price_diff_total_str, sep = ' || ', end="\r", flush=True)
				confirmation = 0



def process_message_stop_market(msg): # Websockets listener and processing for trailing stop type
	global highest_price
	global confirmation
	global price_diff_int_prev
	for currency in msg:
		x = currency_container(currency)
		if(x.symbol == order_symbol): 
			current_price = x.bid_price
			
			# Calculate percentage total profit/loss

			price_diff_total = ((current_price - buy_avg_price) / buy_avg_price) * 100
			price_diff_total = round(price_diff_total, 2)
			price_diff_total = price_diff_total + 0.0 # eliminates - sign for 0.00 rounded value


			# Substract fee percentage (buy and sell) from total profit/loss percentage, if mode is 'Reset' only count selling fee

			if commission_asset == "BNB":
				if order_mode == "Reset":
					price_diff_total -= (fee_bnb / 2)
				else:
					price_diff_total -= fee_bnb
			else:
				if order_mode == "Reset":
					price_diff_total -= (fee_other / 2)
				else:
					price_diff_total -= fee_other

			current_price_str = '[c] ' + '{0:.{precision}f}'.format(current_price, precision=price_precision)
			order_stop_price_str = '[s] ' + '{0:.{precision}f}'.format(order_stop_price, precision=price_precision)

			price_diff_total_str = '[p/l] ' +  '{0:.{precision}f}'.format(price_diff_total, precision='2')	

			# Add whitespace to non negative percentages to preserve consistent console output spacing

			if price_diff_total >= 0:
				price_diff_total_str = '[p/l]  ' +  '{0:.{precision}f}'.format(price_diff_total, precision='2')	

			if current_price <= order_stop_price: # If trailing stop condition is met

				# If amount of confirmations set is not reached print to console in yellow
				
				print(Fore.YELLOW, end=" ")
				print (x.symbol, current_price_str,order_stop_price_str,price_diff_total_str, sep = ' || ', end="\r", flush=True)				

				confirmation += 1

				# If amount of confirmations set is reached print to console in red, close websocket and initiate position exit

				if confirmation == order_confirmations:
					print(Fore.RED, end=" ")
					print (x.symbol, current_price_str,order_stop_price_str,price_diff_total_str, sep = ' || ', end="\r", flush=True)	
					print("\n")				
					bm.close()

					# In test mode set the 'sell' price to ask price at the moment stop was triggered, in Real or Reset mode initiate market sell order

					if order_mode == "Test":
						sell_avg_price = current_price
						sell_avg_price_str = '{0:.{precision}f}'.format(sell_avg_price, precision=price_precision)
					else:
						try:
							sell_avg_price = exit_position()
						except:
							message = " Sell order for " + str(order_amount) + " " + order_symbol + " failed!\n Check your balances and sell manually if needed"
							print(Fore.RED)
							print(message)
							if len(telegram_api) > 0:
								try:							
									send_message (message)
								except:
									pass
							bm.close()
							break

						sell_avg_price_str = '{0:.{precision}f}'.format(sell_avg_price, precision=price_precision)

						# Recalculate total profit/loss based on the actual weighted average sell price, if mode is 'Reset' only count selling fee

						price_diff_total = ((sell_avg_price - buy_avg_price) / buy_avg_price) * 100
						price_diff_total = round(price_diff_total, 2)

						if commission_asset == "BNB":
							if order_mode == "Reset":
								price_diff_total -= (fee_bnb / 2)
							else:
								price_diff_total -= fee_bnb
						else:
							if order_mode == "Reset":
								price_diff_total -= (fee_other / 2)
							else:
								price_diff_total -= fee_other


					# Remove [p/l] suffix from total profit/loss percentage string
					
					price_diff_total_str = '{0:.{precision}f}'.format(price_diff_total, precision='2')

					message = " Stop-Market for " + order_symbol + " triggered, entered at: " + buy_avg_price_str + " sold at: " + sell_avg_price_str + "\n" + " Profit/Loss(incl. fees): " + price_diff_total_str + " %"
					print(Fore.CYAN)
					print(message)

					# Send Telegram message if API key is set

					if len(telegram_api) > 0:
						try:							
							send_message (message)
						except:
							pass

			else: # If stop market condition is not met write to console in green and reset stop confirmation count
				print(Fore.GREEN, end=" ")				
				print (x.symbol, current_price_str,order_stop_price_str,price_diff_total_str, sep = ' || ', end="\r", flush=True)
				confirmation = 0

			



if __name__ == "__main__":
	os.system('mode con: cols=92 lines=8') # Set console window size
	console_title = order_symbol + " - " + order_type + " - " + order_mode
	ctypes.windll.kernel32.SetConsoleTitleW(console_title) # Set console window title
	init() # Initialize colorama

	# Open Binance API connection, exit if failure

	print(Style.BRIGHT, "Initialising trader...", end="\r", flush=True)
	
	try:
		client = Client(api_key, api_secret)		
		print(" Initialised successfully!",end="\r", flush=True)
		
	except:
		print(" Error - press any key to exit...")
		input()
		sys.exit(0)

	# Call function to get Binance price and qty minimum values for symbol

	price_precision,qty_precision = get_symbol_info()

	# Set order amount precision to allowed precision

	order_amount = math.floor(order_amount * 10 ** 2) / 10 ** 2
	
	# If start price is set create listener for coin price, continue when start price is reached

	start_match = False

	if order_start_price > 0:

		info = client.get_ticker(symbol=order_symbol)
		start_ask = float(info.get("askPrice"))

		if start_ask > order_start_price:
			start_mode = "high"
		else:
			start_mode = "low"

		while not start_match:
			info = client.get_ticker(symbol=order_symbol)
			current_ask = float(info.get("askPrice"))
			current_ask_str = '{0:.{precision}f}'.format(current_ask, precision=price_precision)
			order_start_price_str = '{0:.{precision}f}'.format(order_start_price, precision=price_precision)
			message = " Tracking if start price is met, current ask price = " + current_ask_str + " start price = " + order_start_price_str
			print(Fore.YELLOW,end="\r", flush=True)
			print(message,end="\r", flush=True)

			if start_mode == "high":
				if order_start_price >= current_ask:
					start_match = True

			if start_mode == "low":
				if order_start_price <= current_ask:
					start_match = True			
		
		sys.stdout.write("\033[K")						
			

	# If mode is 'Real' enter position

	if order_mode == 'Real':	
		try:
			buy_avg_price,buy_qty,commission_asset = enter_position()
			buy_avg_price_str = '{0:.{precision}f}'.format(buy_avg_price, precision=price_precision)
			buy_qty_str = '{0:.{precision}f}'.format(buy_qty, precision=qty_precision)
			message = " Successful buy order executed for " + buy_qty_str + " amount of " + order_symbol + " for an avg price of " + buy_avg_price_str
			print(Fore.CYAN,end="\r", flush=True)
			print(message)
			print(Fore.WHITE)
		except:
			print(Fore.RED)
			message = " Something went wrong executing buy order for " + str(order_amount) + " amount of " + order_symbol + " please check your settings/balances" 
			print(message,end="\r", flush=True)
			input()
			sys.exit(1)
			
	
	# If mode is 'Test' or 'Reset' get current ask price and use that as 'buy' price		

	else:
		info = client.get_ticker(symbol=order_symbol)

		# If mode is 'Test' start tracking from current ask price, simulating a buy. If not start tracking from current bid price

		if order_mode == "Test":
			buy_avg_price = float(info.get("askPrice"))
			start_type = "ask"
		else:
			buy_avg_price = float(info.get("bidPrice"))
			start_type = "bid"

		buy_avg_price_str = '{0:.{precision}f}'.format(buy_avg_price, precision=price_precision)
		commission_asset = "BNB"
		print(Fore.CYAN,end="\r", flush=True)
		message = " Started tracking price for " + order_symbol + " at " + start_type + " price " + buy_avg_price_str
		print (message)
		print(Fore.WHITE)
	
	if order_type == "Trailing Stop":	
		bm = BinanceSocketManager(client)
		conn_key = bm.start_ticker_socket(process_message_trailing_stop)
		bm.start()

	if order_type == "Stop-Market":	
		bm = BinanceSocketManager(client)
		conn_key = bm.start_ticker_socket(process_message_stop_market)
		bm.start()


	# If mode is 'Reset' check if symbol balance is enough for sell order for amount requested

	if order_mode == "Reset":
		symbol_short = order_symbol[:-3]
		balance = client.get_asset_balance(asset=symbol_short)
		balance_free = float(balance.get("free"))
		if order_amount > balance_free:
			print(Fore.RED)
			message = " Current balance for " + order_symbol + " is not sufficient to satisfy specified sell amount, \n please check your settings/balances"
			print(message)
			bm.close()
			
		buy_qty = order_amount	

# Set first highest price to the buy price

highest_price = buy_avg_price

# Set initial values for effective trail percentage calculations

price_diff_int_max = 0

effective_trail_percentage = order_trail_percentage

# Declare confirmation variable

confirmation = 0

# Keyboard listener for up/down arrow effective trail percentage adjustments


def on_press(key):
	global effective_trail_percentage
	try:
		key_pressed = '{0}'.format(key)
		w = win32gui
		active_window = w.GetWindowText (w.GetForegroundWindow())
		if(active_window == console_title):
			if key_pressed == 'Key.up':
				effective_trail_percentage += 0.1			
			if key_pressed == 'Key.down':
				effective_trail_percentage -= 0.1
	except:
		pass	


with keyboard.Listener(
        on_press=on_press) as listener:
    try:
        listener.join()
    except:
    	pass
    	

    





