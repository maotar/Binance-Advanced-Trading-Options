# Binance Advanced Trading Options #

Currently under development, trading not available.

![alt text](https://i.imgur.com/K8kGKOB.png "GUI")

Status :

* 7-March-2018 - Initial commit, GUI available for feedback/testing
* 19-March-2018 - Trader available for testing

## Introduction ##

Additional trading options for the Binance cryptocurrency exchange, current order types available are 'Trailing Stop' and 'Stop-Market'. GUI is provided to set and execute trades, for each trade a seperate trader console window will be opened that will do the tracking and will execute the buy and/or sell orders.

**Use at your own risk! Read all the information below carefully and use the test mode until you are comfortable to make a real trade.**

**Eventhough they will be encrypted make sure to never enable withdrawals for a Binance API key pair, restrict their use to the public IP of the computer(s) you will be using them from and periodically delete and generate a new ones.**

**The application runs client side, if a trader window is closed or if your computer is turned off or rebooted the stops will no longer be active. Windows 10 automatic updates are known to forcefully reboot your PC at times so make sure to disable this 'feature' if you have trades running for longer periods.** 

**Windows has a feature for console windows that will pause execution when mouseclick is done in the window to enable text copy/paste from it, of course we don't want this to happen when the trader is running, To disable this feature right click the title bar of any console window (can be a test trader or regular CMD window), choose 'Defaults' and then uncheck the 'Quick Edit' checkbox. Any future console/trader window will now open without the quick edit feature enabled.**

## Requirements ##

* Python 3.6, https://www.python.org/downloads/release/python-364/
* Python modules python-binance, colorama, pywin32, pynput (open CMD prompt as administrator and execute 'pip install 
  *insertmodulename*' for each module)
* Autohotkey, https://autohotkey.com/download/

Download the file structure to a local folder.

Start the application by running start.ahk

## GUI Usage ##

### API Connection

![alt text](https://i.imgur.com/2QUWnHY.png)

When the application starts for the first time it will ask for the keys necessary to connect to the Binance API and/or Telegram API, all keys will be AES encrypted and can only be decrypted with the encryption password set in this dialog (password is not stored anywhere, if you lose it or want to reconfigure the connection settings just delete the hashes.txt file in Resources\Text\ and restart the application). On future application starts only the decryption password will need to be entered:

![alt text](https://i.imgur.com/PVkddut.png)


If you leave both the 'Enable Trade Mode' and 'Enable Telegram' checkboxes unchecked and click 'Submit' the application will launch in Test mode requiring no API keys.

For information how to set up Telegram for notifications check here: https://www.forsomedefinition.com/automation/creating-telegram-bot-notifications/

### Main GUI

1. Trailing Stop

   Trader will track and compare the current bid price against the highest bid price since execution, if the difference is
   equal or greater than the percentage set in options a market sell order will be placed.

   Fields:
   * Symbol (required), enter full trade pair name like BNBBTC or BNBETH, will be validated against currently available pairs 
     (list gets updated every 3 minutes)
   * Amount (required), the quantity of coins to buy, fractional numbers are supported, digits beyond the allowed precision for
     the symbol will be ignored
   * Start Price (optional, activated through checkbox next to input field), advanced feature, trader will wait to enter the 
     position until the start price is met. If set above ask price at time of execution it will wait until the current ask price
     is higher or equal than the specified start price (could be used to trigger buy on potential breakout). If set below ask
     price at time of execution it will wait until the current ask price is lower or equal than the specified start price (could
     be used to trigger buy on potential bounce point)
   * Trail % (required), percentage difference compared to highest price till sell order is triggered
   * Ratio (required, set to 0 if not desired), advanced feature, percentage increase of Trail % per percent profit compared to
     enter price, think of it as adaptive trail percentage (e.g. Trail % = 1, Ratio = 0.2, current profit = 3.1%, effective
     trail percentage = 1.6%)
   * Confirmations (required), trader will track current ask price every second, after the amount of confirmations (seconds 
     where sell condition will be met) the sell order will be placed, think of it as the sensitivity of the trailing stop

2. Stop-Market

   Trader will track and compare the current bid price against the price set in 'Stop Price' field, if the current bid price is
   equal or lower a market sell order will be placed.
   
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
   trading option for coins already bought with the Binance default trading options. Trader will check balances before starting
   tracking to make sure they are sufficient to fulfill sell order.

## Trader Usage ##

For each executed trade a seperate console window will be opened that shows the tracking information and buy/sell order results, what will be displayed depends on the order type and mode :

### Trailing Stop:

(optional) If Start Price is specified trader will start ask price listener and wait until start price is met:

![alt text](https://i.imgur.com/ofdOAEL.png)

![alt text](https://i.imgur.com/bNzZlcV.png "Trader")

Trade start:

1. Real

   If succesful the trader will display the amount of coins purchased (can be lower than set amount if fee asset is not set to
   BNB or if BNB balance is not sufficient) and the weighted average price of the fills for the order
2. Test

   Trader will display the current **ask** price it will start tracking profit/loss percentage from simulating a market buy.
3. Reset
   Trader will display the current **bid** price it will start tracking profit/loss percentage from
   
Tracking:

The trader will display the tracking information refreshing every second in the below format:

SYMBOL || [c] (current bid price) || [h] (highest bid price) || [etp] (effective trail %) || [ctp] (current trail %) || [p/l] profit/loss %

* [etp] The effective trail percentage based on the Trail % set in GUI, the Ratio set in GUI and manual adjustment (**if trader
  window is active you can adjust the etp on the fly by using the up and down arrows on your keyboard**)

* [ctp] The difference between the highest bid price and current bid price, if equal or lower than the effective trail      
  tracking line will be displayed in yellow until the amount of confirmations is reached after which (simulated) sell order will
  be placed
  
* [p/l] Percentage total profit/loss, will be measured from the (simulated) buy order therefore taking in account the spread and 
  will take in account the fees for buy and sell order for Real and Test mode, and only sell order fees for Reset mode
   
Trade stop:

Trader will perform the (simulated) sell order, display the results in console and if configured will send Telegram message. 

1. Real/Reset
   Trader will execute and show the details of the sell order and will display the re-calculated total profit/loss based on the
   weighted average of the sell order fills, as the sell order is a market order the profit/loss percentage can be lower than
   the p/l indicated in the tracker at the time the stop is triggered.
2. Test
   Trader will show result of simulated sell order based on the bid price at the time of stop trigger

### Stop-Market:

Same as Trailing stop exept for the info displayed in tracking mode :

![alt text](https://i.imgur.com/uBTB1WM.png "Trader")

SYMBOL || [c] (current bid price) || [s] (stop price)|| [p/l] profit/loss %

