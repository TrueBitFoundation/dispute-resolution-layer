const BasicVerificationGame = artifacts.require("./BasicVerificationGame.sol")
const SimpleAdderVM = artifacts.require("./test/SimpleAdderVM.sol")
const web3 = require('web3')

const toResult = (data) => {
  return {
    state: data[0],
    stateHash: data[1]
  }
}

contract('BasicVerificationGame query to high step', function(accounts) {
  let basicVerificationGame, simpleAdderVM, gameId

  let program = [ 
    "0x0000000000000000000000000000000000000000000000000000000000000001",
    "0x0000000000000000000000000000000000000000000000000000000000000002",
    "0x0000000000000000000000000000000000000000000000000000000000000003",
    "0x0000000000000000000000000000000000000000000000000000000000000004",
    "0x0000000000000000000000000000000000000000000000000000000000000005",
    "0x0000000000000000000000000000000000000000000000000000000000000006",
    "0x0000000000000000000000000000000000000000000000000000000000000007",
    "0x0000000000000000000000000000000000000000000000000000000000000008",
    "0x0000000000000000000000000000000000000000000000000000000000000009"
  ]   

  let programLength = program.length - 1
  let output = 45
  let step = programLength - 1
  let responseTime = 20

  before(async () => {
    basicVerificationGame = await BasicVerificationGame.deployed()
    simpleAdderVM = await SimpleAdderVM.deployed()
  })

  it("should create a new verification game", async () => {
    let programMerkleRoot = await basicVerificationGame.merklizeProof.call(program)
    let tx = await basicVerificationGame.newGame(accounts[1], accounts[2], programMerkleRoot, web3.utils.soliditySha3(output), programLength, responseTime, SimpleAdderVM.address)
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

  it("should respond to query", async () => {
    let result = toResult(await simpleAdderVM.runSteps.call(program, step))

    let tx = await basicVerificationGame.respond(gameId, step, result.stateHash, {from: accounts[1]})

    let response = tx.logs[0].args
    assert.equal(response.hash, result.stateHash)
    assert.equal(response.gameId, gameId)
  })

  //This needs to be fixed as it is rather awkward....
  it("should query a step again...", async () => {
    //query final step to make verification game short
    let tx = await basicVerificationGame.query(gameId, step, {from: accounts[2]})

    let query = tx.logs[0].args
    assert.equal(query.stepNumber.toNumber(), step)
    assert.equal(query.gameId, gameId)
  })

  it("should perform step verification", async () => {
    let preStep = toResult(await simpleAdderVM.runSteps.call(program, step))
    let postStep = await simpleAdderVM.runStep.call(preStep.state, program[step+1])

    let merkleProof = [
      await basicVerificationGame.merklizeProof.call(program.slice(0, -1)),
      "0x0000000000000000000000000000000000000000000000000000000000000009"
    ]

    tx = await basicVerificationGame.performStepVerification(gameId, preStep.state, postStep, merkleProof, {from: accounts[1]})
    //assert.equal(1, (await basicVerificationGame.status.call(gameId)).toNumber())
  })
})

//TODO: Make test where game queries to low step