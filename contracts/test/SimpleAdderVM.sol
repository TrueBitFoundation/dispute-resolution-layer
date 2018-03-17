pragma solidity ^0.4.18;

import "../IComputationLayer.sol";

contract SimpleAdderVM is IComputationLayer {

  //Only part used for interface
  function runStep(uint currentState, uint nextInstruction) public returns (uint newState) {
    newState = currentState + nextInstruction;
  }

  //Used for generating results for query/response
  function runSteps(uint[] program, uint numSteps) public pure returns (uint state, bytes32 stateHash) {
    uint i = 0;
    uint sum = 0;
    while (i < program.length && i <= numSteps) {
      sum += program[i];
      i++;
    }
    state = sum;
    stateHash = keccak256(state);
  }
  
}