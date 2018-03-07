from binance.client import Client
import json
import math
import time
import sys
import requests
import urllib


# Binance API connection


api_key = ""
api_secret = ""


client = Client(api_key, api_secret)

info = client.get_exchange_info()

text_path = sys.argv[1] + "\Resources\Text\Symbols.txt"
#text_path = "E:\Code\Trading\Trailing Stop\Resources\Text\Symbols.txt"


print (text_path)


text_file = open(text_path, "w")

for symbol in info["symbols"]:
	symbol_name = (symbol["symbol"])
	symbol_line = symbol_name + "\n"
	text_file.write(symbol_line)

text_file.close()