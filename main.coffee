# import packages and config
https = require "https"
Web3 = require "web3"
web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/m7Pdc77PjIwgmp7t0iKI"))
config = require "./config.json"

# import Ethereum account
key = require "./key.json"
password = (require "./password").password
account = web3.eth.accounts.decrypt(key, password)

wait = (time) ->
    return new Promise(
        (resolve) ->
            setTimeout(resolve, time)
    )

updateFeed = () ->
    # wait for block to be mined
    waitTime = 10000 # 2.5 minutes in milliseconds
    await wait(waitTime)

    # fetch prices
    apiStr = "https://min-api.cryptocompare.com/data/pricemulti?fsyms=" +
        config.tokens.join() + "&tsyms=DAI"
    data = await (new Promise((resolve, reject) ->
        https.get(apiStr, (res) ->
            data = ""
            res.on("data", (chunk) ->
                data += chunk
            )
            res.on("end", () ->
                parsedData = JSON.parse(data)
                resolve(parsedData)
            )
        ).on("error", reject)
    ))

    # update price in TestKyberNetwork smart contract
    console.log data

    updateFeed()

updateFeed()