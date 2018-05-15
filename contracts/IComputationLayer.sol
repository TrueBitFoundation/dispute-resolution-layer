pragma solidity ^0.4.18;

interface IComputationLayer {
    function runStep(bytes32 currentState, bytes32 nextInput) public pure returns (bytes32 newState);
    function merklizeState(bytes32 state) public pure returns (bytes32 merkleRoot);
}