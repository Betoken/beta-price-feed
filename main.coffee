# import packages and config
https = require "https"
Web3 = require "web3"
infuraKey = require "./infura_key.json"
web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/v3/" + infuraKey))
config = require "./config.json"

# load KyberNetwork contract interface
kn_abi = require("./TestKyberNetwork.json").abi
TestKyberNetwork = new web3.eth.Contract(kn_abi, config.kyber_address)

factory_abi = require("./TestTokenFactory.json").abi
TestTokenFactory = new web3.eth.Contract(factory_abi, config.factory_address)

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

# Uses TestTokenFactory to obtain a token's address from its symbol
tokenSymbolToAddress = (_symbol) ->
    symbolHash = web3.utils.soliditySha3(_symbol)
    return TestTokenFactory.methods.createdTokens(symbolHash).call()

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
            rawData = ""
            res.on("data", (chunk) ->
                rawData += chunk
            )
            res.on("end", () ->
                parsedData = JSON.parse(rawData)
                resolve(parsedData)
            )
        ).on("error", reject)
    ))

    tokenPrices = config.tokens.map((token) -> data[token].DAI * config.precision)
    ###
        data takes the following format:
        {
            ETH: {
                DAI: 450
            },
            OMG: {
                DAI: 0.123
            }
        }
    ###

    tokenAddresses = await Promise.all(config.tokens.map(
        (symbol) -> 
            addr = await tokenSymbolToAddress(symbol)
            return addr
    ))

    # update price in TestKyberNetwork smart contract
    txData = TestKyberNetwork.methods.setAllTokenPrices(tokenAddresses, tokenPrices).encodeABI()
    tx = await account.signTransaction({
        to: config.kyber_address
        gas: 1200000
        data: txData
    })
    web3.eth.sendSignedTransaction(tx.rawTransaction)
    .on("transactionHash", console.log)
    .on("receipt", console.log)

    # recurse to simulate an infinite loop
    updateFeed()

updateFeed()