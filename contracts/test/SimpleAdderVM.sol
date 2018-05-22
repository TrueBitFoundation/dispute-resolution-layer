pragma solidity ^0.4.18;

import "./SimpleAdderInput.sol";
import "./SimpleAdderState.sol";
import "../IComputationLayer.sol";

contract SimpleAdderVM is IComputationLayer {

    //Used directly only to run on chain computation, otherwise use runSteps
    function runStep(bytes32[3] currentState, bytes32 nextInput) external pure returns (bytes32[3] newState) {
        // Get registers
        var (sum, stepNumber) = SimpleAdderState.getRegisters(currentState);

        // Get input
        uint nextNumber = SimpleAdderInput.getNumber(nextInput);

        // Update state
        sum += nextNumber;
        stepNumber += 1;

        // Get new state
        newState = SimpleAdderState.getState(nextNumber, sum, stepNumber);
    }

    //Simple list merklization (works like sum)
    function merklizeState(bytes32[3] state) external pure returns (bytes32 merkleRoot) {
        for (uint i = 0; i < state.length; i++) {
            if (i == 0) {
                merkleRoot = state[0];
            } else {
                merkleRoot = keccak256(merkleRoot, state[i]);
            }
        }
    }

    //Used for generating results for query/response
    //Run offchain
    function runSteps(bytes32[] program, uint numSteps) external view returns (bytes32[3] state, bytes32 stateHash) {
        for (uint i = 0; i < program.length && i < numSteps; i++) {
            bytes32 nextInstruction = program[i];
            state = this.runStep(state, nextInstruction);
        }

        stateHash = this.merklizeState(state);
    }
}
