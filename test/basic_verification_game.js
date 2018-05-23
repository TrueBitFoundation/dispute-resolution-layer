// Copyright (C) 2018 TrueBit
// See Copyright Notice in LICENSE-MIT.txt

const BasicVerificationGame = artifacts.require("./BasicVerificationGame.sol")
const SimpleAdderVM = artifacts.require("./test/SimpleAdderVM.sol")
const web3 = require('web3')
const merkleTree = require('./helpers/merkleTree')
const sha3 = require('ethereumjs-util').sha3

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

  let programLength = program.length
  let output = 45
  let step = 1
  let responseTime = 20
  let checkProofOrderedSolidity
  let mtree
  let hashes = program.map(e => sha3(e))
  let root

  before(async () => {
    basicVerificationGame = await BasicVerificationGame.deployed()
    simpleAdderVM = await SimpleAdderVM.deployed()
    checkProofOrderedSolidity = merkleTree.checkProofOrderedSolidityFactory(basicVerificationGame.checkProofOrdered)
    // Set flag to true to be ordered
    mtree = new merkleTree.MerkleTree(hashes, true)
    root = mtree.getRoot()
  })

  it("should challenge and initialize", async () => {
    let tx = await basicVerificationGame.commitChallenge(accounts[1], accounts[2], web3.utils.soliditySha3("spec usually goes here"), {from: accounts[2]})

    let log = tx.logs[0]

    gameId = log.args.gameId

    await basicVerificationGame.initGame(gameId, merkleTree.bufToHex(root), web3.utils.soliditySha3(output), programLength, responseTime, SimpleAdderVM.address, {from: accounts[2]})
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

  it("should query next step down", async () => {
    //query final step to make verification game short
    let tx = await basicVerificationGame.query(gameId, step-1, {from: accounts[2]})

    let query = tx.logs[0].args
    assert.equal(query.stepNumber.toNumber(), step-1)
    assert.equal(query.gameId, gameId)
  })

  it("should perform step verification", async () => {
    let lowStepState = toResult(await simpleAdderVM.runSteps.call(program, step-1)).state

    let highStep = step
    let highStepIndex = step-1
    let highStepState = await simpleAdderVM.runStep.call(lowStepState, program[highStepIndex])

    let proof = mtree.getProofOrdered(hashes[highStepIndex], highStep)
    const newProof = '0x' + proof.map(e => e.toString('hex')).join('')

    assert(await checkProofOrderedSolidity(proof, root, hashes[highStepIndex], highStep))

    tx = await basicVerificationGame.performStepVerification(gameId, lowStepState, highStepState, newProof, {from: accounts[1]})
    assert.equal(3, (await basicVerificationGame.status.call(gameId)).toNumber())
  })
})