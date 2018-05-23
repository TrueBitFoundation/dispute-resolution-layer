// Copyright (C) 2018 TrueBit
// See Copyright Notice in LICENSE-MIT.txt

pragma solidity ^0.4.18;

interface IComputationLayer {
    function runStep(bytes32[3] currentState, bytes32 nextInput) external pure returns (bytes32[3]  newState);
    function merklizeState(bytes32[3] state) external pure returns (bytes32 merkleRoot);
}