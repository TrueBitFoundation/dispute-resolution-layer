// Copyright (C) 2018 TrueBit
// See Copyright Notice in LICENSE-MIT.txt

pragma solidity ^0.4.21;

/**
 * @title Input abstraction library for simple adder
 */
library SimpleAdderInput {
  /**
   * @notice Translate an input frame into an operand for the adder
   *
   * @param input The VM input, encoded as bytes32
   *
   * @return The number used as input for the adder
   */
  function getNumber(bytes32 input) public pure returns (uint number) {
    number = uint(input);
  }
}
