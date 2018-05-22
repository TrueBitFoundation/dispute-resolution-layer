pragma solidity ^0.4.18;

import "../IComputationLayer.sol";

contract SimpleAdderVM is IComputationLayer {

    //Used directly only to run on chain computation, otherwise use runSteps
    //VM State (4 Registers):
    //Reg0: Stack0 Input
    //Reg1: Stack2 Result
    //Reg2: StepCounter
    function runStep(bytes32[3] currentState, bytes32 nextInput) external pure returns (bytes32[3] newState) {
        newState[0] = nextInput;
        newState[1] = bytes32(uint(currentState[1]) + uint(nextInput));
        newState[2] = bytes32(uint(currentState[2]) + 1);
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
