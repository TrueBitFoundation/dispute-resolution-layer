pragma solidity ^0.4.18;

interface IComputationLayer {
  function runStep(uint currentState, uint instruction) public returns (uint output);
}