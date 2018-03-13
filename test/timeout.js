const BasicVerificationGame = artifacts.require("./BasicVerificationGame.sol")
const SimpleAdderVM = artifacts.require("./test/SimpleAdderVM.sol")
const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))
const mineBlocks = require('./helpers/mineBlocks')

const toResult = (data) => {
  return {
    state: "0x" + data[0].slice(-2),//because of encoding issues, uhhhh....
    stateHash: data[1]
  }
}

contract('Timeout Game with no query', function(accounts) {
  let basicVerificationGame, simpleAdderVM, gameId

  let program = "0x010203040506070809"
  let programLength = (program.length / 2) - 2
  let output = "0x000000000000000000000000000000000000000000000000000000000000002d"//45
  let step = programLength - 1
  let outputHash = web3.utils.soliditySha3(output)
  let responseTime = 20

  before(async () => {
    basicVerificationGame = await BasicVerificationGame.new()
    simpleAdderVM = await SimpleAdderVM.new()
  })

  it("should create a new verification game", async () => {
    let tx = await basicVerificationGame.newGame(accounts[1], accounts[2], program, outputHash, programLength, responseTime, SimpleAdderVM.address)
    const result = tx.logs[0].args
    gameId = result.gameId
    assert.equal(result.solver, accounts[1])
    assert.equal(result.verifier, accounts[2])
  })

  it("should trigger timeout", async () => {
    await mineBlocks(web3, responseTime + 5)
    //query final step to make verification game short
    await basicVerificationGame.timeout(gameId, {from: accounts[1]})

    assert.equal(1, await basicVerificationGame.status.call(gameId))
  })
})

contract('Timeout game with no response', function(accounts) {
  let basicVerificationGame, simpleAdderVM, gameId

  let program = "0x010203040506070809"
  let programLength = (program.length / 2) - 2
  let output = "0x000000000000000000000000000000000000000000000000000000000000002d"//45
  let step = programLength - 1
  let outputHash = web3.utils.soliditySha3(output)
  let responseTime = 20

  before(async () => {
    basicVerificationGame = await BasicVerificationGame.new()
    simpleAdderVM = await SimpleAdderVM.new()
  })

  it("should create a new verification game", async () => {
    let tx = await basicVerificationGame.newGame(accounts[1], accounts[2], program, outputHash, programLength, responseTime, SimpleAdderVM.address)
    const result = tx.logs[0].args
    gameId = result.gameId
    assert.equal(result.solver, accounts[1])
    assert.equal(result.verifier, accounts[2])
  })

  it("should query a step", async () => {
    //query final step to make verification game short
    let tx = await basicVerificationGame.query(gameId, step, {from: accounts[2]})

    let query = tx.logs[0].args
    assert.equal(query.stepNumber.toNumber(), step)
    assert.equal(query.gameId, gameId)
  })

  it("should trigger timeout", async () => {
    await mineBlocks(web3, responseTime + 10)
    //query final step to make verification game short
    await basicVerificationGame.timeout(gameId, {from: accounts[2]})

    assert.equal(2, await basicVerificationGame.status.call(gameId))
  })
})