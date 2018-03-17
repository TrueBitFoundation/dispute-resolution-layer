module.exports = (web3, program) => {

  let temp = []
  for(n in program) temp.push(web3.utils.soliditySha3(n))

  function merkleLeaves(program) {
    hashes = []
    for(let i = 0; i < program.length; i++) {
      if(i % 2 != 0) {
        hashes.push(web3.utils.soliditySha3(program[i-1], program[i]))
      } else if(i == program.length - 1) {
        hashes.push(program[i])
      }
    }
  
    return hashes
  }

  while(temp.length > 1) {
    temp = merkleLeaves(temp)
  }

  return temp[0]
}