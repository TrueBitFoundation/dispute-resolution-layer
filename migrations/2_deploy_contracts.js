const DisputeResolutionLayer = artifacts.require("./DisputeResolutionLayer.sol");

module.exports = function(deployer) {
  deployer.deploy(DisputeResolutionLayer);
};
