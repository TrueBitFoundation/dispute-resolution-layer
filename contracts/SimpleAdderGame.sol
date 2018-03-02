pragma solidity ^0.4.18;

import './IDisputeResolutionLayer.sol';

contract SimpleAdderGame is IDisputeResolutionLayer {

  uint numGames = 0;

  event NewQuery(uint gameId, uint stepNumber);
  event NewResponse(uint gameId, bytes32 hash);
  event DataLog(byte data);

  function newGame(uint taskId, address solver, address challenger, bytes input, bytes32 outputHash, uint numSteps) public returns(uint gameId) {
    numGames = numGames + 1;
    return numGames - 1;
  }

  function query(uint gameId, uint stepNumber) public {
    NewQuery(gameId, stepNumber);
  }

  function respond(uint gameId, bytes32 hash) public {
    NewResponse(gameId, hash);
  }
 
  function timeout(uint gameId) public {

  }

  function runToStep(bytes program, uint numSteps) constant returns (uint state, bytes32 stateHash) {
    uint i = 0;
    while(i < program.length || i < numSteps) {
      uint n = uint(program[i]);
      state = state + n;
      i = i + 1;
    }
    stateHash = keccak256(state);
  }

  function performFinalVerification(uint sessionId, uint claimId, bytes preValue, bytes postValue, bytes proof) public {

  }
}