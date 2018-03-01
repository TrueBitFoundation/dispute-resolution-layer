pragma solidity ^0.4.18;

interface IDisputeResolutionLayer {
  function newGame(uint taskId, address solver, address challenger, bytes input, bytes32 outputHash, uint numSteps) public returns(uint gameId);

  function query(uint gameId, uint stepNumber) public;

  function respond(uint gameId, bytes32 hash) public;
 
  function timeout(uint gameId) public;

  function performFinalVerification(uint sessionId, uint claimId, bytes preValue, bytes postValue, bytes proof) public;

}