// Copyright (C) 2018 TrueBit
// See Copyright Notice in LICENSE-MIT.txt

const SimpleAdderVM = artifacts.require("./test/SimpleAdderVM.sol")

module.exports = function(deployer) {
  deployer.deploy(SimpleAdderVM)
}