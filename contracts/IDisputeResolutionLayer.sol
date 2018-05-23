// Copyright (C) 2018 TrueBit
// See Copyright Notice in LICENSE-MIT.txt

pragma solidity ^0.4.18;

//TODO: Should maybe enforce checkProofOrdered
interface IDisputeResolutionLayer {
    function status(bytes32 id) external view returns (uint8); //returns State enum
    function commitChallenge(address solver, address verifier, bytes32 spec) external returns (bytes32 gameId);
}