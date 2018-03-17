module.exports = (web3, program) => {

  let proof = []

  let temp = []
  for(n in program) temp.push(web3.utils.soliditySha3(n))

  function merkleLeaves(program) {
    let hashes = []

    for(let i = 0; i < program.length; i++) {
      if(i % 2 != 0) {
        hashes.push(web3.utils.soliditySha3(program[i-1], program[i]))
      } else if(i == program.length - 1) {
        hashes.push(program[i])
      }
    }

    proof.unshift(hashes)
  
    return hashes
  }

  while(temp.length > 1) {
    let hashes = merkleLeaves(temp)
    temp = merkleLeaves(hashes)
  }

  return proof
}