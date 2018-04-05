// Copyright (C) 2018 TrueBit
// See Copyright Notice in LICENSE-MIT.txt

const BasicVerificationGame = artifacts.require("./BasicVerificationGame.sol")
const web3 = require('web3')
const merkleTree = require('./helpers/merkleTree')
const sha3 = require('ethereumjs-util').sha3

contract('Simple test environment for generating merkle trees', function(accounts) {
  let basicVerificationGame, gameId

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
  let checkProofOrderedSolidity
  let mtree
  let hashes = program.map(e => sha3(e))

  before(async () => {
    basicVerificationGame = await BasicVerificationGame.deployed()
    checkProofOrderedSolidity = merkleTree.checkProofOrderedSolidityFactory(basicVerificationGame.checkProofOrdered)
    // Set flag to true to be ordered
    mtree = new merkleTree.MerkleTree(hashes, true)
  })

  it("should check merkle proof", async () => {
    const root = mtree.getRoot()
    const index = 0
    const proof = mtree.getProofOrdered(hashes[index], 1-index)

    assert(await checkProofOrderedSolidity(proof, root, hashes[index], 1-index))
  })

})