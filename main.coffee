# import packages and config
https = require "https"
Web3 = require "web3"
infuraKey = (require "./infura_key.json").key
web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/" + infuraKey))
config = require "./config.json"

# import Ethereum account
key = require "./key.json"
password = (require "./password").password
account = web3.eth.accounts.decrypt(key, password)

# a function that, well, waits. time is in milliseconds
wait = (time) ->
    return new Promise(
        (resolve) ->
            setTimeout(resolve, time)
    )

# main function
updateFeed = () ->
    # wait for block to be mined
    waitTime = 2.5 * 60 * 1000 # 2.5 minutes in milliseconds
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