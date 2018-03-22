pragma solidity ^0.4.18;

contract SimpleAdderVM {

  //Used directly only to run on chain computation, otherwise use runSteps
  //VM State (4 Registers):
  //Reg0: Stack0 Input
  //Reg1: Stack1 Accum
  //Reg2: Stack2 Result
  //Reg3: StepCounter
  function runStep(bytes32[4] currentState, bytes32 nextInput) public pure returns (bytes32[4] newState) {

    newState[0] = nextInput;//Copy input
    newState[1] = currentState[2];//Copy last result as new accum

    //Use Stack0 and Stack1 registers to compute result
    bytes32 sum = bytes32(uint(newState[0]) + uint(currentState[1]));//Add input by the previous state's accum
    newState[2] = sum;//Store result in Stack2 register

    newState[3] = bytes32(uint(currentState[3]) + 1);//Increment step counter
  }

  //Simple list merklization (works like sum)
  function merklizeState(bytes32[4] state) public pure returns (bytes32 merkleRoot) {
    for (uint i = 0; i < state.length; i++) {
      if (i == 0) {
        merkleRoot = state[0];
      } else {
        merkleRoot = keccak256(merkleRoot, state[i]);
      }
    }
  }

  //Used for generating results for query/response
  //Run offchain
  function runSteps(uint[] program, uint numSteps) public pure returns (bytes32[4] state, bytes32 stateHash) {
    uint i = 0;

    while (i < program.length && i <= numSteps-1) {
      bytes32 nextInstruction = bytes32(program[uint(state[3])]);
      state = runStep(state, nextInstruction);
      i+=1;
    }

    stateHash = merklizeState(state);
  }
  
}