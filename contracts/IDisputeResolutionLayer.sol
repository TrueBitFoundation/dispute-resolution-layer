pragma solidity ^0.4.18;

interface IDisputeResolutionLayer {
  function newGame(address solver, address verifier, bytes input, bytes32 outputHash, uint numSteps) public returns(uint gameId);

  function query(uint gameId, uint stepNumber) public;

  function respond(uint gameId, bytes32 hash) public;
 
  function timeout(uint gameId) public returns (bool);

  function performStepVerification(uint gameId, bytes preValue, bytes postValue, bytes proof) public returns (bool);

}