const SimpleAdderGame = artifacts.require("./SimpleAdderGame.sol")
const TaskManager = artifacts.require("./TaskManager.sol")

module.exports = function(deployer) {
  deployer.deploy(SimpleAdderGame)
  deployer.deploy(TaskManager)
}
