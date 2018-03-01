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

  function decodeState(bytes state) internal pure returns(uint[] decodedState) {
    // for(uint i = 0; i < state.length; i++) {
    //   decodedState.push(uint(state[i]));
    // }
  }

  function performFinalVerification(uint sessionId, uint claimId, bytes preValue, bytes postValue, bytes proof) public {

  }
}