pragma solidity ^0.4.18;

import "./IComputationLayer.sol";

contract SimpleAdderVM is IComputationLayer {
  function runStep(bytes currentState, bytes nextInstruction) public returns (bytes32 newState) {
    newState = bytes32(uint(currentState[0]) + uint(nextInstruction[0]));
  }

  // function runSteps(bytes program, uint numSteps) public pure returns (uint state, bytes32 stateHash) {
  //   uint i = 0;
  //   while (i < program.length && i <= numSteps) {
  //     uint n = uint(program[i]);
  //     state = runStep(state, n);
  //     i = i + 1;
  //   }
  //   stateHash = keccak256(state);
  // }
}