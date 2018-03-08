const BasicVerificationGame = artifacts.require("./BasicVerificationGame.sol")

module.exports = function(deployer) {
  deployer.deploy(BasicVerificationGame)
}