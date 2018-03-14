# Binance Advanced Trading Options #

Currently under development, trading not available.

![alt text](https://i.imgur.com/K8kGKOB.png "GUI")

Status :

* 7-March-2018 - Initial commit, GUI available for feedback/testing

## Introduction ##

Additional trading options for the Binance Cryptocurrency exchange, current order types available are 'Trailing Stop' and 'Stop-Market'. GUI is provided to set and execute trades, for each trade a seperate trader console window will be opened that will do the tracking and will execute the buy and/or sell orders

**Use at your own risk! Use the test mode until you are comfortable to make a real trade**

**The program runs client side, if a trader window is closed or your computer is turned off or rebooted the stops will no longer be active, Windows 10 automatic updates will forcefully reboot your PC so make sure to disable this 'feature' if you have trades running for longer periods, consider setting Binance default stop-limit under stop price/percentage to act as safety net** 

## Requirements ##

* Python 3.6
* Python modules python-binance, colorama, pywin32, pynput (open CMD prompt as administrator and execute 'pip install 
  insertmodulename' for each module)
* Autohotkey, https://autohotkey.com/download/

Download the file structure to a local folder, open trader.py from Resources\Python folder and put in your Binance API keys.

(Optional) To receive Telegram notification when a stop is triggered enter your Telegram API key and conversation ID in trader.py

Start the application by running start.ahk

## GUI Usage ##
1. Trailing Stop

   Trader will track and compare the current bid price against the highest bid price since execution, if the difference is
   equal or greater than the percentage set in options a market sell order will be placed.

   Fields:
   * Symbol (required), enter full trade pair name like BNBBTC or BNBETH, will be validated against currently available pairs 
     (list gets updated every 3 minutes)
   * Amount (required), the quantity of coins to buy, fractional numbers are supported, digits beyond the allowed precision for
     the symbol will be ignored
   * Start Price (Optional, activated through checkbox next to input field), advanced feature, trader will wait to enter the 
     position until current ask price is equal or above start price specified
   * Trail % (required), percentage difference compared to highest price till sell order is triggered
   * Ratio (required, set to 0 if not desired), advanced feature, percentage increase of Trail % per percent profit compared to
     enter price, think of it as adaptive trail percentage (e.g. Trail % = 1, Ratio = 0.2, current profit = 3.1%, effective
     trail percentage = 1.6%)
   * Confirmations (required), trader will track current ask price every second, after the amount of confirmations (seconds 
     where sell condition will be met) the sell order will be placed, think of it as the sensitivity of the trailing stop

2. Stop-Market

   Trader will track and compare the current bid price against the price set in 'Stop Price' field, if the current bid price is
   equal or lower a market sell order will be placed
   
   Fields:
   * Symbol (required), enter full trade pair name like BNBBTC or BNBETH, will be validated against currently available pairs 
     (list gets updated every 3 minutes)
   * Amount (required), the quantity of coins to buy, fractional numbers are supported, digits beyond the allowed precision for
     the symbol will be ignored
   * Stop Price (required), the price at which the sell order will be placed if current bid price is equal or lower than this
     value (make sure this is set lower than current bid price, stop profit not (yet) supported)
   * Confirmations (required), trader will track current bid price every second, after the amount of confirmations (seconds 
     where sell condition will be met) the sell order will be placed, think of it as the sensitivity of the trailing stop
     
### Modes:

1. Real

   Trader will execute both buy order and sell order
2. Test

   Trader will not execute any buy or sell order
3. Reset

   Trader will not execute buy order but will execute sell order if stop conditions are met, use to use the
   trading option for coins already bought with the Binance default trading options. Make sure your Binance account balance for
   the symbol is sufficient for the amount specified or the sell order will fail

## Trader Usage ##

For each executed trade a seperate console window will be opened that shows the tracking information and buy/sell order results, what will be displayed depends on the order type and mode :

### Trailing Stop:

Trade start:

1. Real

   If succesful the trader will display the amount of coins purchased (can be lower than set amount if fee asset is not set to
   BNB or if BNB balance is not sufficient) and the weighted average price of the fills for the order
2. Test

   Trader will display the current **ask** price it will start tracking profit/loss percentage from simulating a market buy.
3. Reset
   Trader will display the current **bid** price it will start tracking profit/loss percentage from
   
Tracking:

The trader will display the tracking information refreshing every second in the below format

SYMBOL || [c] (current bid price) || [h] (highest bid price) || [etp] (effective trail %) || [ctp] (current trail %) || [p/l] profit/loss %

* [etp] The effective trail percentage based on the Trail % set in GUI, the Ratio set in GUI and manual adjustment (**if trader
  window is active you can adjust the etp on the fly by using the up and down arrows on your keyboard**)

* [ctp] The difference between the highest bid price and current bid price, if equal or lower than the effective trail      
  tracking line will be displayed in yellow until the amount of confirmations is reached after which (simulated) sell order will
  be placed
  
* [p/l] Percentage total profit/loss, will be measured from the (simulated) buy order therefore taking in account the spread and 
  will take in account the fees for buy and sell order for Real and Test mode, and only sell order fees for Reset mode
   



