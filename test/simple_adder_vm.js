// Copyright (C) 2018 TrueBit
// See Copyright Notice in LICENSE-MIT.txt

const SimpleAdderVM = artifacts.require("./test/SimpleAdderVM.sol")
const web3 = require('web3')

const toResult = (data) => {
  return {
    state: "0x" + data[0].slice(-2),//because of encoding issues, uhhhh....
    stateHash: data[1]
  }
}

contract('SimpleAdderVM', function(accounts) {
  let simpleAdderVM

  let program = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

  before(async () => {
    simpleAdderVM = await SimpleAdderVM.deployed()
  })

  it("should merklize state", async () => {
    assert.equal(
      "0xce14df43546288f0a098d4057077c167f41c3cbcd4011965d53430d2e99d3dfb",
      await simpleAdderVM.merklizeState.call(["1", "2", "3", "4"])
    )
  })

  it("should run a step", async () => {
    assert.deepEqual(
      await simpleAdderVM.runStep.call(
        ["0x00", "0x00", "0x00", "0x00"], 
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      ),
      [ '0x0000000000000000000000000000000000000000000000000000000000000001',
        '0x0000000000000000000000000000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000000000000000000000000001',
        '0x0000000000000000000000000000000000000000000000000000000000000001'
      ]
    )
  })

  it("should run steps", async () => {
    assert.deepEqual(
      await simpleAdderVM.runSteps.call(program, 5),
      [ 
        [ '0x0000000000000000000000000000000000000000000000000000000000000004',
          '0x0000000000000000000000000000000000000000000000000000000000000004',
          '0x0000000000000000000000000000000000000000000000000000000000000006',
          '0x0000000000000000000000000000000000000000000000000000000000000005' 
        ],
        '0x00b6b0f456d4b05f44bd2f7ad745e2350d8dfd0bd68cdda97c011e988ca58998' 
      ]
    )
  })
})