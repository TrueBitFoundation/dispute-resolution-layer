const SimpleAdderGame = artifacts.require("./SimpleAdderGame.sol")
const web3 = require('web3')

const toResult = (data) => {
  return {
    state: data[0].toNumber(),
    stateHash: data[1]
  }
}

contract('SimpleAdderGame', function(accounts) {
  let simpleAdderGame, gameId

  let program = "0x010203040506070809"
  let programLength = (program.length / 2) - 2
  let output = 45
  let step = programLength - 1
  let outputHash = web3.utils.soliditySha3(output)

  before(async () => {
    simpleAdderGame = await SimpleAdderGame.deployed()
  })

  it("should create a new verification game", async () => {
    let tx = await simpleAdderGame.newGame(accounts[1], accounts[2], program, outputHash, programLength)
    const result = tx.logs[0].args
    gameId = result.gameId.toNumber()
    assert.equal(result.solver, accounts[1])
    assert.equal(result.verifier, accounts[2])
  })

  it("should query a step", async () => {
    //query final step to make verification game short
    let tx = await simpleAdderGame.query(gameId, step, {from: accounts[2]})

    let query = tx.logs[0].args
    assert.equal(query.stepNumber.toNumber(), step)
    assert.equal(query.gameId.toNumber(), gameId)
  })

  it("should respond to query", async () => {
    let result = toResult(await simpleAdderGame.runSteps.call(program, step))

    let tx = await simpleAdderGame.respond(gameId, result.stateHash, {from: accounts[2]})

    let response = tx.logs[0].args
    assert.equal(response.hash, result.stateHash)
    assert.equal(response.gameId.toNumber(), gameId)
  })

  it("should perform step verification", async () => {
    let result = toResult(await simpleAdderGame.runSteps.call(program, step))
    let verified = await simpleAdderGame.performStepVerification.call(gameId, result.state, "0x09", web3.utils.soliditySha3(output))
    assert(verified, "step verification was false")
  })
})