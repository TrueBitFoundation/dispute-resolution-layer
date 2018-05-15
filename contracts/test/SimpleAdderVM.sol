pragma solidity ^0.4.18;

import "../IComputationLayer.sol";

contract SimpleAdderVM is IComputationLayer {

    //Used directly only to run on chain computation, otherwise use runSteps
    function runStep(bytes32 currentState, bytes32 nextInput) public pure returns (bytes32 newState) {
        newState = bytes32(uint(currentState) + uint(nextInput));
    }

    function merklizeState(bytes32 state) public pure returns (bytes32 merkleRoot) {
        merkleRoot = keccak256(state);
    }

    //Used for generating results for query/response
    //Run offchain
    function runSteps(bytes32[] program, uint numSteps) public pure returns (bytes32 state, bytes32 stateHash) {
        for (uint i = 0; i < program.length && i < numSteps; i++) {
            bytes32 nextInstruction = program[i];
            state = runStep(state, nextInstruction);
        }

        stateHash = merklizeState(state);
    }

}