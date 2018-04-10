const fs = require('fs')
const SimpleAdderVM = artifacts.require("./test/SimpleAdderVM.sol")
const BasicVerificationGame = artifacts.require("./BasicVerificationGame.sol")

module.exports = (deployer, network) => {
  let exportedContracts = {}

  let contracts = [SimpleAdderVM, BasicVerificationGame]

  contracts.forEach((contract) => {

    exportedContracts[contract.contractName] = {
      abi: contract.abi,
      address: contract.address
    }
  })

  if (!fs.existsSync(__dirname + "/../export/")){
    fs.mkdirSync(__dirname + "/../export/")
  }

  let path = __dirname + "/../export/" + network+ ".json"

  fs.writeFile(path, JSON.stringify(exportedContracts), (e) => {if(e) console.error(e) })
}