module.exports = {
  runCode: (code) => {
    let stack = []
    let pc = 0
    for(let i = 0; i < code.length; i++) {
      stack.push(code[i])
    }

    let end_of_program = false

    //compute stack
    while(!end_of_program) {
      let val = stack.pop()
      let val2 = stack.pop()
      let result = val + val2
      stack.push(result)

      if(stack.length < 2) end_of_program = true
      pc = pc + 1
    }

    return stack
  },
  runToStep: (code, step) => {
    let stack = []
    let pc = 0
    for(let i = 0; i < code.length; i++) {
      stack.push(code[i])
    }

    let end_of_program = false
    while(!end_of_program) {
      let val = stack.pop()
      let val2 = stack.pop()
      let result = val + val2
      stack.push(result)

      if(stack.length < 2 || pc >= step) end_of_program = true
      pc = pc + 1
    }

    return stack
  },
  decodeProgram: (program) => {
    let stack = []
    for(i = 0; i < program.length; i++) {
      stack.push(parseInt(program[i]))
    }
    return stack
  },
  encodeState: (stack) => {
    let state = ""
    for(n in stack) state = state + n
    return state
  }
}