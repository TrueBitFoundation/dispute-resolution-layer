pragma solidity ^0.4.18;

import "../IComputationLayer.sol";

contract SimpleAdderVM is IComputationLayer {
  function runStep(bytes currentState, bytes nextInstruction) public returns (bytes32 newState) {
    newState = bytes32(uint(currentState[0]) + uint(nextInstruction[0]));
  }
}