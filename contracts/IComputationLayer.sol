// Copyright (C) 2018 TrueBit
// See Copyright Notice in LICENSE-MIT.txt

pragma solidity ^0.4.18;

/**
 * @title Computation layer interface
 */
interface IComputationLayer {
    /**
     * @notice Run a step of the VM
     *
     * @param currentState The current VM state, encoded as bytes32[3]
     * @param nextInput The input for the step, encoded as bytes32
     *
     * @return The new game state, encoded as bytes32[3]
     */
    function runStep(bytes32[3] currentState, bytes32 nextInput) external pure returns (bytes32[3] newState);

    /**
     * @notice Get a hash of the game state
     *
     * @param state The game state
     *
     * @return merkleRoot A Merkle root for the state
     */
    function merklizeState(bytes32[3] state) external pure returns (bytes32 merkleRoot);
}
