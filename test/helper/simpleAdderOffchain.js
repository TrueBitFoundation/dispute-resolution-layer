module.exports = async (vm, program, numSteps) => {
  let i = 2//skip 0x
  let programLength = (program.length - 2) / 2
  let parsedProgram = []
  let state = "0x00"

  for(steps = 0; steps < programLength; steps++) {
    parsedProgram.push("0x" + program.slice(i, i+2))
    i+=2
  }

  return parsedProgram.reduce(async (currentState, instruction) => {
    return await vm.runStep.call(await currentState, instruction)
  }, "0x00")
}