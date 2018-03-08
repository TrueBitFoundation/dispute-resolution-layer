pragma solidity ^0.4.18;

import "../IComputationLayer.sol";

contract SimpleAdderVM is IComputationLayer {

  //Only part used for interface
  function runStep(bytes currentState, bytes nextInstruction) public returns (bytes32 newState) {
    newState = bytes32(uint(currentState[0]) + uint(nextInstruction[0]));
  }

  //Used for generating results for query/response
  function runSteps(bytes program, uint numSteps) public pure returns (bytes32 state, bytes32 stateHash) {
    uint i = 0;
    uint sum = 0;
    while (i < program.length && i <= numSteps) {
      sum += uint(program[i]);
      i++;
    }
    state = bytes32(sum);
    stateHash = keccak256(state);
  }

  //sanity checker
  function getHash(bytes32 n) public pure returns (bytes32) {
    return keccak256(n);
  }

  //sanity checker
  function runStepHash(bytes currentState, bytes nextInstruction) public returns (bytes32 newState) {
    newState = keccak256(bytes32(uint(currentState[0]) + uint(nextInstruction[0])));
  }
}