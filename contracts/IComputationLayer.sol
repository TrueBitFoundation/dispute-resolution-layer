pragma solidity ^0.4.18;

interface IComputationLayer {
  function runStep(bytes currentState, bytes instruction) public returns (bytes32 output);
}