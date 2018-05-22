// Copyright (C) 2018 TrueBit
// See Copyright Notice in LICENSE-MIT.txt

pragma solidity ^0.4.21;

/**
 * @title State abstraction library for simple adder
 *
 * @dev VM state has 3 registers:
 *
 *   - Reg0: Input
 *   - Reg1: Result
 *   - Reg2: StepCounter
 */
library SimpleAdderState {
  /**
   * @notice Translate a VM state into register values
   *
   * @param state The VM state, encoded as bytes32[3]
   *
   * @return The register values
   */
  function getRegisters(bytes32[3] state) public pure returns (uint sum, uint stepNumber) {
    sum = uint(state[1]);
    stepNumber = uint(state[2]);
  }

  /**
   * @notice Translate register values into a VM state
   *
   * @param input The input to the adder
   * @param result The resulting sum
   * @param stepNumber The step number that produced the sum
   *
   * @return The VM state, encoded as bytes32[3]
   */
  function getState(uint input, uint result, uint stepNumber) public pure returns (bytes32[3] state) {
    state[0] = bytes32(input);
    state[1] = bytes32(result);
    state[2] = bytes32(stepNumber);
  }
}
