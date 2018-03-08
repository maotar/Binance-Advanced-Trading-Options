# Binance Advanced Trading Options #

Currently under development, trading not available.

Status :

* 7-March-2018 - Initial commit, GUI available for feedback/testing

## Introduction ##

Additional trading options for the Binance Cryptocurrency exchange, current order types available are 'Trailing Stop' and 'Stop-Market'.

**Use at your own risk! Use the test mode until you are comfortable to make a real trade**

## Requirements ##

* Python 3.6, pip install twisted, pip install python-binance
* Autohotkey, https://autohotkey.com/download/

Download the file structure to a local folder and run start.ahk

## Usage ##
1. Trailing Stop

   Trader will track and compare the current ask price against the highest ask price since activation, if the difference is
   greater than the percentage set in options a market sell order will be placed.

   Fields:
   * Symbol (required), enter full trade pair name like BNBBTC or BNBETH, will be validated against currently available pairs.
   * Amount (required), the quantity of coins to buy, currently does not accept fractional numbers, only full coins
   * Start Price (Optional, activated through checkbox next to input field), advanced feature, trader will wait to enter the 
     position until start price is reached
   * Trail % (required), percentage difference compared to highest price till sell order is triggered
   * Ratio (required, set to 0 if not), advanced feature, percentage increase of Trail % per percent profit compared to enter 
     price, think of it as adaptive trail percentage (e.g. Trail % = 1, Ratio = 0.2, current profit = 3%, effective trail 
     percentage = 1.6%)
   * Confirmations (required), trader will track current ask price every second, after the amount of confirmations (seconds 
     where sell condition will be met) the sell order will be placed, think of it as the sensitivity of the trailing stop

2. Stop-Market

   Trader will track and compare the current ask price against the price set in 'Stop Price' field, if the current ask price is
   equal or lower a market sell order will be placed
   
   Fields:
   * Symbol (required), enter full trade pair name like BNBBTC or BNBETH, will be validated against currently available pairs.
   * Amount (required), the quantity of coins to buy, currently does not accept fractional numbers, only full coins
   * Stop Price (required), the price at which the sell order will be placed if current ask price is equal or lower than this
     value
   * Confirmations (required), trader will track current ask price every second, after the amount of confirmations (seconds 
     where sell condition will be met) the sell order will be placed, think of it as the sensitivity of the trailing stop
     
### Modes:

1. Real

   Trader will execute both buy order and sell order
2. Test

   Trader will not execute any buy or sell order
3. Reset

   Trader will not execute buy order but will execute sell order if conditions are met, use to reset the counter or to use the
   trading option for coins already bought with the Binance integrated trading options



