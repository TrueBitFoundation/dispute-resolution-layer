const SimpleAdderGame = artifacts.require("./SimpleAdderGame.sol")

module.exports = function(deployer) {
  deployer.deploy(SimpleAdderGame)
}
