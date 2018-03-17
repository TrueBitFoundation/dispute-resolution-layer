const SimpleAdderVM = artifacts.require("./test/SimpleAdderVM.sol")
const merkleRoot = require('./helpers/merkleRoot')
const web3 = require('web3')

const toResult = (data) => {
  return {
    state: "0x" + data[0].slice(-2),//because of encoding issues, uhhhh....
    stateHash: data[1]
  }
}

contract('SimpleAdderVM', function(accounts) {
  let simpleAdderVM

  let program = "0x010203040506070809"
  let output = "0x000000000000000000000000000000000000000000000000000000000000002d"//45
  let step = (program.length / 2 - 2) - 1

  before(async () => {
    simpleAdderVM = await SimpleAdderVM.deployed()
  })

  // it("should properly add numbers", async () => {
  //   assert.equal(
  //     "0x0000000000000000000000000000000000000000000000000000000000000003",
  //     await simpleAdderVM.runStep.call("0x01", "0x02")
  //   )
  // })

  // it("should properly run steps", async () => {
  //   assert.equal(
  //     "0x24",
  //     toResult(await simpleAdderVM.runSteps.call(program, step)).state
  //   )
  // })

  // it("should generate merkle root", async () => {
  //   let program = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  //   console.log(merkleRoot(web3, program))
  // })
})