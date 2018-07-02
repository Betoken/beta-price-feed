# import packages and config
https = require "https"
Web3 = require "web3"
web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/m7Pdc77PjIwgmp7t0iKI"))
config = require "config"

# import Ethereum account
key = require "./key"
password = require "./password"
account = web3.eth.accounts.decrypt(key, password)

wait = (time) ->
    return new Promise(
        (resolve) ->
            setTimeout(resolve, time)
    )

while true
    # wait for block to be mined
    waitTime = 2.5 * 60 * 1000 # 2.5 minutes in milliseconds
    await wait(waitTime)

    # fetch prices
    apiStr = "https://min-api.cryptocompare.com/data/pricemulti?fsyms=" +
        config.tokens.join() + "&tsyms=DAI"
    https.get(apiStr, (res) ->
        res.on("data", (data) ->
            console.log data
        )
    ).on("error", (error) ->
        console.log error
    )

    # update price feed