pragma solidity ^0.4.18;

interface IComputationLayer {
    function runStep(bytes32[3] currentState, uint stepNumber, bytes32 nextInput) public pure returns (bytes32[3]  newState);
    function merklizeState(bytes32[3] state) public pure returns (bytes32 merkleRoot);
}