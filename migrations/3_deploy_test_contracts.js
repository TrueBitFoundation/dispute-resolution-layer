const SimpleAdderVM = artifacts.require("./test/SimpleAdderVM.sol")

module.exports = function(deployer) {
  deployer.deploy(SimpleAdderVM)
}