// Copyright (C) 2018 TrueBit
// See Copyright Notice in LICENSE-MIT.txt

const BasicVerificationGame = artifacts.require("./BasicVerificationGame.sol")
const SimpleAdderVM = artifacts.require("./test/SimpleAdderVM.sol")
const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))
const mineBlocks = require('./helpers/mineBlocks')
const merkleTree = require('./helpers/merkleTree')
const sha3 = require('ethereumjs-util').sha3

const toResult = (data) => {
  return {
    state: "0x" + data[0].slice(-2),//because of encoding issues, uhhhh....
    stateHash: data[1]
  }
}

contract('Timeout Game with no query', function(accounts) {
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
    let tx = await basicVerificationGame.commitChallenge(accounts[1], accounts[2], web3.utils.soliditySha3("spec goes here"), {from: accounts[2]})

    let log = tx.logs[0]

    gameId = log.args.gameId

    await basicVerificationGame.initGame(gameId, merkleTree.bufToHex(root), web3.utils.soliditySha3(output), programLength, responseTime, SimpleAdderVM.address, {from: accounts[2]})
  })

  it("should trigger timeout", async () => {
    await mineBlocks(web3, responseTime + 5)
    //query final step to make verification game short
    await basicVerificationGame.timeout(gameId, {from: accounts[1]})

    assert.equal(3, (await basicVerificationGame.status.call(gameId)).toNumber())
  })
})

contract('Timeout game with no response', function(accounts) {
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
    let tx = await basicVerificationGame.commitChallenge(accounts[1], accounts[2], web3.utils.soliditySha3("spec goes here"), {from: accounts[2]})

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

  it("should trigger timeout", async () => {
    await mineBlocks(web3, responseTime + 10)
    //query final step to make verification game short
    await basicVerificationGame.timeout(gameId, {from: accounts[2]})

    assert.equal(4, (await basicVerificationGame.status.call(gameId)).toNumber())
  })
})