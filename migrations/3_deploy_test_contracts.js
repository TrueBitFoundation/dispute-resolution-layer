const SimpleAdderInput = artifacts.require("./test/SimpleAdderInput.sol")
const SimpleAdderState = artifacts.require("./test/SimpleAdderState.sol")
const SimpleAdderVM = artifacts.require("./test/SimpleAdderVM.sol")

module.exports = function(deployer) {
  deployer.deploy(SimpleAdderInput)
  deployer.deploy(SimpleAdderState)

  deployer.link(SimpleAdderInput, SimpleAdderVM)
  deployer.link(SimpleAdderState, SimpleAdderVM)
  deployer.deploy(SimpleAdderVM)
}